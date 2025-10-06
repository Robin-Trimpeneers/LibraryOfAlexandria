import config from './config.js';

document.addEventListener('DOMContentLoaded', () => {
    const registerForm = document.getElementById('registerForm');
    const messageDiv = document.getElementById('registerMessage');
    const loadingOverlay = document.getElementById('loadingOverlay');

    registerForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        clearMessages();

        const name = document.getElementById('registerName').value.trim();
        const email = document.getElementById('registerEmail').value.trim();
        const password = document.getElementById('registerPassword').value;

        if (!validateInputs(name, email, password)) return;

        try {
            showLoading(true);

            // Register the user and get the response data
            const data = await registerUser(name, email, password);

            // Store the JWT token in localStorage
            //localStorage.setItem('token', data.token); // Adjust 'token' based on your server's response key

            showMessage('Registration successful, redirecting...', 'success');
            setTimeout(() => {
                window.location.href = '../library.html';
            }, 5000);
        } catch (error) {
            console.error('Registration error:', error);
            showMessage(error.message, 'danger');
        } finally {
            showLoading(false);
        }
    });

    async function registerUser(name, email, password) {
        console.log(config.API_URL)
        const response = await fetch(`${config.API_URL}/auth/users`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'include',
           
            body: JSON.stringify({
                email: email,
                password: password,
                name: name
            })
        });

        const data = await response.json();

        if (!response.ok) {
            // If the server sends an error message, throw it
            throw new Error(data.message || 'Registration failed');
        }

        return data; // Return the parsed response data
    }

    function showLoading(show) {
        loadingOverlay.style.display = show ? 'flex' : 'none';
    }

    function showMessage(message, type) {
        messageDiv.textContent = message;
        messageDiv.className = `alert alert-${type} show`;
        setTimeout(() => {
            messageDiv.className = 'alert';
            messageDiv.textContent = '';
        }, 5000);
    }

    function validateInputs(name, email, password) {
        if (!name || !email || !password) {
            showMessage('All fields are required', 'danger');
            return false;
        }
        if (!validateEmail(email)) {
            showMessage('Invalid email format', 'danger');
            return false;
        }
        if (password.length < 8) {
            showMessage('Password must be at least 8 characters', 'danger');
            return false;
        }
        return true;
    }

    function validateEmail(email) {
        const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return re.test(email);
    }

    function clearMessages() {
        messageDiv.textContent = '';
        messageDiv.className = 'alert';
    }
});