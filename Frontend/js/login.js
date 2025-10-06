import config from './config.js';

document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('loginForm');
    const messageDiv = document.getElementById('loginMessage');
    const loadingOverlay = document.getElementById('loadingOverlay');
    checkForHttpOnlyCookie

    function clearJwtCookie() {
        document.cookie = 'JWT=; Path=/; Expires=Thu, 01 Jan 1970 00:00:01 GMT;';
    }

    // Check for remembered email
    const rememberedEmail = localStorage.getItem('rememberedEmail');
    if (rememberedEmail) {
        document.getElementById('email').value = rememberedEmail;
        document.getElementById('rememberMe').checked = true;
    }

    loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        clearMessages();

        const email = document.getElementById('email').value.trim();
        const password = document.getElementById('password').value;
        const rememberMe = document.getElementById('rememberMe').checked;

        if (!validateInputs(email, password)) return;

        try {
            showLoading(true);

            const response = await fetch(`${config.API_URL}/auth/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ email, password }),
                credentials: 'include'
            });

            await handleResponse(response);
            checkForHttpOnlyCookie(); // Check if HttpOnly cookie is set

            handleRememberMe(rememberMe, email);
        } catch (error) {
            console.error('Login error:', error);
            showMessage(error.message, 'danger');
        } finally {
            showLoading(false);
        }
    });

    function validateInputs(...inputs) {
        for (const input of inputs) {
            if (!input) {
                showMessage('All fields are required', 'danger');
                return false;
            }
        }
        if (!/\S+@\S+\.\S+/.test(inputs[0])) {
            showMessage('Invalid email format', 'danger');
            return false;
        }
        return true;
    }

    async function handleResponse(response) {
        const text = await response.text();
        try {
            const data = text ? JSON.parse(text) : {};
            if (!response.ok) {
                throw new Error(data.message || 'Login failed');
            }
            return data;
        } catch {
            throw new Error(text || 'Login failed');
        }
    }

    function handleRememberMe(rememberMe, email) {
        if (rememberMe) {
            localStorage.setItem('rememberedEmail', email);
        } else {
            localStorage.removeItem('rememberedEmail');
        }
    }

    function checkForHttpOnlyCookie() {
        fetch(`${config.API_URL}/auth/check-cookie`, { credentials: 'include' })
            .then(response => {
                console.log('Cookie check response:', response.status);
                if (response.ok) {
                    console.log('Login successful, redirecting...');
                    window.location.href = '/library.html';
                } else {
                    console.log('No valid session found');
                }
            })
            .catch(error => console.error('Error checking cookie:', error));
    }

    function showLoading(show) {
        loadingOverlay.style.display = show ? 'flex' : 'none';
    }

    function showMessage(message, type) {
        messageDiv.textContent = message;
        messageDiv.className = `alert alert-${type} mt-3`;
        setTimeout(() => messageDiv.classList.remove('alert-' + type), 5000);
    }

    function clearMessages() {
        messageDiv.textContent = '';
        messageDiv.className = '';
    }
});
