const { body, validationResult } = require('express-validator');

// Handle validation errors
const handleValidation = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
};

// Registration validation
const registerValidation = [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').isEmail().normalizeEmail().withMessage('Invalid email'),
  body('mobile').matches(/^[6-9]\d{9}$/).withMessage('Invalid mobile number'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  handleValidation
];

// Provider registration validation
const providerRegisterValidation = [
  ...registerValidation.slice(0, -1),
  body('shop_name').trim().notEmpty().withMessage('Shop name is required'),
  body('category').trim().notEmpty().withMessage('Category is required'),
  body('location').trim().notEmpty().withMessage('Location is required'),
  handleValidation
];

// Login validation
const loginValidation = [
  body('identifier').notEmpty().withMessage('Email or mobile is required'),
  body('password').notEmpty().withMessage('Password is required'),
  handleValidation
];

// Service validation
const serviceValidation = [
  body('service_name').trim().notEmpty().withMessage('Service name is required'),
  body('category').trim().notEmpty().withMessage('Category is required'),
  body('rate').isFloat({ min: 1 }).withMessage('Rate must be at least 1'),
  handleValidation
];

// Booking validation
const bookingValidation = [
  body('provider_id').isInt().withMessage('Provider ID is required'),
  body('service_id').isInt().withMessage('Service ID is required'),
  body('booking_date').isDate().withMessage('Invalid date'),
  body('slot_time').matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/).withMessage('Invalid time format'),
  handleValidation
];

module.exports = {
  registerValidation,
  providerRegisterValidation,
  loginValidation,
  serviceValidation,
  bookingValidation,
  handleValidation
};
