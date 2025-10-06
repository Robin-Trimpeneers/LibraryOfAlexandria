// config.js
const config = {
    API_URL: window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1' 
        ? 'http://localhost:8080/api' 
        : `${window.location.protocol}//${window.location.host}`,
    AUTH_COOKIE_NAME: 'JWT',
    DEFAULT_BOOK_COVER: '/assets/default-book-cover.jpg',
    NOTIFICATION_DURATION: 5000,
    ISBN_REGEX: /^(?:\d{10}|\d{13})$/,
    EMAIL_REGEX: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
    ERRORS: {
        NETWORK: 'Network error. Please check your connection.',
        INVALID_ISBN: 'Please enter a valid 10 or 13 digit ISBN',
        INVALID_EMAIL: 'Please enter a valid email address',
        SERVER_ERROR: 'An error occurred. Please try again later.',
        UNAUTHORIZED: 'Please log in to continue'
    }
};

// Freeze the config object to prevent modifications
Object.freeze(config);

export default config;