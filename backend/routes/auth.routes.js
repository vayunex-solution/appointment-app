const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { registerValidation, providerRegisterValidation, loginValidation } = require('../middleware/validator');
const { authenticate } = require('../middleware/auth');

// Customer registration
router.post('/register/customer', registerValidation, authController.registerCustomer);

// Provider registration
router.post('/register/provider', providerRegisterValidation, authController.registerProvider);

// Verify email
router.post('/verify-email', authController.verifyEmail);

// Resend verification code
router.post('/resend-verification', authController.resendVerification);

// Login
router.post('/login', loginValidation, authController.login);

// Forgot password
router.post('/forgot-password', authController.forgotPassword);

// Reset password
router.post('/reset-password', authController.resetPassword);

// Get current user profile (protected)
router.get('/profile', authenticate, authController.getProfile);

// Google Sign-In
router.post('/google', authController.googleLogin);

module.exports = router;
