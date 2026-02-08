const User = require('../models/User');
const Provider = require('../models/Provider');
const db = require('../config/db');
const { sendEmail, emailTemplates } = require('../config/smtp');
const { generateToken } = require('../middleware/auth');

// Store verification codes temporarily (In production, use Redis)
const verificationCodes = new Map();

// Generate 6-digit code
const generateCode = () => Math.floor(100000 + Math.random() * 900000).toString();

// Customer Registration
exports.registerCustomer = async (req, res) => {
    try {
        const { name, email, mobile, password, device_id } = req.body;

        // Check if email/mobile already exists
        if (await User.emailExists(email)) {
            return res.status(400).json({ error: 'Email already registered' });
        }
        if (await User.mobileExists(mobile)) {
            return res.status(400).json({ error: 'Mobile number already registered' });
        }

        // Create user
        const userId = await User.create({
            name, email, mobile, password, role: 'customer', device_id
        });

        // Generate and send verification code
        const code = generateCode();
        verificationCodes.set(email, { code, userId, expires: Date.now() + 600000 });

        await sendEmail(email, 'Verify Your Email', emailTemplates.verification(name, code));

        res.status(201).json({
            message: 'Registration successful. Please verify your email.',
            userId
        });
    } catch (error) {
        console.error('Register error:', error);
        res.status(500).json({ error: 'Registration failed' });
    }
};

// Provider Registration
exports.registerProvider = async (req, res) => {
    try {
        const { name, email, mobile, password, shop_name, category, location } = req.body;

        if (await User.emailExists(email)) {
            return res.status(400).json({ error: 'Email already registered' });
        }
        if (await User.mobileExists(mobile)) {
            return res.status(400).json({ error: 'Mobile number already registered' });
        }

        // Create user
        const userId = await User.create({
            name, email, mobile, password, role: 'provider'
        });

        // Create provider profile
        await Provider.create({ user_id: userId, shop_name, category, location });

        // Generate and send verification code
        const code = generateCode();
        verificationCodes.set(email, { code, userId, expires: Date.now() + 600000 });

        await sendEmail(email, 'Verify Your Email', emailTemplates.verification(name, code));

        res.status(201).json({
            message: 'Registration successful. Please verify your email. Admin approval required.',
            userId
        });
    } catch (error) {
        console.error('Register error:', error);
        res.status(500).json({ error: 'Registration failed' });
    }
};

// Verify Email
exports.verifyEmail = async (req, res) => {
    try {
        const { email, code } = req.body;

        const stored = verificationCodes.get(email);
        if (!stored || stored.code !== code) {
            return res.status(400).json({ error: 'Invalid verification code' });
        }
        if (Date.now() > stored.expires) {
            verificationCodes.delete(email);
            return res.status(400).json({ error: 'Code expired. Please request a new one.' });
        }

        await User.setVerified(stored.userId);
        verificationCodes.delete(email);

        const token = generateToken(stored.userId);

        res.json({ message: 'Email verified successfully', token });
    } catch (error) {
        console.error('Verify error:', error);
        res.status(500).json({ error: 'Verification failed' });
    }
};

// Login
exports.login = async (req, res) => {
    try {
        const { identifier, password } = req.body;

        // Check if identifier is email or mobile
        const isEmail = identifier.includes('@');
        const user = isEmail
            ? await User.findByEmail(identifier)
            : await User.findByMobile(identifier);

        if (!user) {
            // Log failed attempt
            await logLoginAttempt(null, req.ip, 'failed', 'User not found');
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Check if blocked
        if (user.is_blocked) {
            return res.status(403).json({ error: 'Account is blocked. Contact support.' });
        }

        // Verify password
        const validPassword = await User.verifyPassword(password, user.password_hash);
        if (!validPassword) {
            await logLoginAttempt(user.id, req.ip, 'failed', 'Wrong password');
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Check if verified
        if (!user.is_verified) {
            return res.status(403).json({ error: 'Please verify your email first', needsVerification: true });
        }

        // Log successful login
        await logLoginAttempt(user.id, req.ip, 'success');

        const token = generateToken(user.id);

        res.json({
            message: 'Login successful',
            token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                mobile: user.mobile,
                role: user.role,
                is_verified: user.is_verified,
                is_blocked: user.is_blocked
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Login failed' });
    }
};

// Resend verification code
exports.resendVerification = async (req, res) => {
    try {
        const { email } = req.body;
        const user = await User.findByEmail(email);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        if (user.is_verified) {
            return res.status(400).json({ error: 'Email already verified' });
        }

        const code = generateCode();
        verificationCodes.set(email, { code, userId: user.id, expires: Date.now() + 600000 });

        await sendEmail(email, 'Verify Your Email', emailTemplates.verification(user.name, code));

        res.json({ message: 'Verification code sent' });
    } catch (error) {
        console.error('Resend error:', error);
        res.status(500).json({ error: 'Failed to resend code' });
    }
};

// Forgot Password
exports.forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;
        const user = await User.findByEmail(email);

        if (!user) {
            return res.json({ message: 'If email exists, a reset code will be sent' });
        }

        const code = generateCode();
        verificationCodes.set(`reset_${email}`, { code, userId: user.id, expires: Date.now() + 600000 });

        await sendEmail(email, 'Password Reset', emailTemplates.passwordReset(user.name, code));

        res.json({ message: 'If email exists, a reset code will be sent' });
    } catch (error) {
        console.error('Forgot password error:', error);
        res.status(500).json({ error: 'Request failed' });
    }
};

// Reset Password
exports.resetPassword = async (req, res) => {
    try {
        const { email, code, newPassword } = req.body;

        const stored = verificationCodes.get(`reset_${email}`);
        if (!stored || stored.code !== code) {
            return res.status(400).json({ error: 'Invalid reset code' });
        }
        if (Date.now() > stored.expires) {
            return res.status(400).json({ error: 'Code expired' });
        }

        await User.updatePassword(stored.userId, newPassword);
        verificationCodes.delete(`reset_${email}`);

        res.json({ message: 'Password updated successfully' });
    } catch (error) {
        console.error('Reset password error:', error);
        res.status(500).json({ error: 'Reset failed' });
    }
};

// Get current user profile
exports.getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        res.json({ user });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch profile' });
    }
};

// Helper: Log login attempts
async function logLoginAttempt(userId, ipAddress, status, notes = null) {
    try {
        await db.execute(
            `INSERT INTO login_logs (user_id, ip_address, status, notes) VALUES (?, ?, ?, ?)`,
            [userId, ipAddress, status, notes]
        );
    } catch (error) {
        console.error('Log error:', error);
    }
}
