const nodemailer = require('nodemailer');

// Create transporter
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT),
  secure: process.env.SMTP_PORT === '465',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASSWORD
  }
});

// Send email function
const sendEmail = async (to, subject, html) => {
  try {
    const mailOptions = {
      from: `"${process.env.SMTP_FROM_NAME}" <${process.env.SMTP_FROM_EMAIL}>`,
      to,
      subject,
      html
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('Email sent:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Email send error:', error);
    return { success: false, error: error.message };
  }
};

// Email templates
const emailTemplates = {
  verification: (name, code) => `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #333;">Email Verification</h2>
      <p>Hello ${name},</p>
      <p>Your verification code is:</p>
      <div style="background: #f5f5f5; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 5px; margin: 20px 0;">
        ${code}
      </div>
      <p>This code will expire in 10 minutes.</p>
      <p>If you didn't request this, please ignore this email.</p>
    </div>
  `,

  passwordReset: (name, code) => `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #333;">Password Reset</h2>
      <p>Hello ${name},</p>
      <p>Your password reset code is:</p>
      <div style="background: #f5f5f5; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 5px; margin: 20px 0;">
        ${code}
      </div>
      <p>This code will expire in 10 minutes.</p>
    </div>
  `,

  bookingConfirmation: (name, details) => `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #333;">Booking Confirmed!</h2>
      <p>Hello ${name},</p>
      <p>Your appointment has been confirmed:</p>
      <div style="background: #f5f5f5; padding: 20px; margin: 20px 0;">
        <p><strong>Token:</strong> ${details.token}</p>
        <p><strong>Service:</strong> ${details.serviceName}</p>
        <p><strong>Provider:</strong> ${details.providerName}</p>
        <p><strong>Date:</strong> ${details.date}</p>
        <p><strong>Time:</strong> ${details.time}</p>
        <p><strong>Amount:</strong> ₹${details.amount}</p>
      </div>
    </div>
  `
};

module.exports = { sendEmail, emailTemplates };
