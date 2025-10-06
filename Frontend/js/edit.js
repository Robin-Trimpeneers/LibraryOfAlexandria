import config from './config.js';

document.addEventListener("DOMContentLoaded", () => {
    preventAccessWithoutCookie();

    function preventAccessWithoutCookie() {
        fetch(`${config.API_URL}/auth/check-cookie`, { credentials: 'include' })
            .then(response => response.json())
            .then(data => {
                if (data.message !== "Cookie found") {
                    window.location.href = '/login.html';
                }
            })
            .catch(error => {
                console.error('Error checking cookie:', error);
                window.location.href = '/login.html';
            });
    }
    
    

    const urlParams = new URLSearchParams(window.location.search);
    
    // Form elements
    const editForm = document.getElementById('editForm');
    const cancelBtn = document.getElementById('cancelBtn');

    // Always show ISBN field for manual additions
    document.getElementById('isbnFieldGroup').style.display = 'block';
    
    // Form submission handler
    editForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const bookData = {
            isbn: document.getElementById('editIsbn').value.trim(),
            title: document.getElementById('editTitle').value,
            author: document.getElementById('editAuthor').value,
            genre: document.getElementById('editGenre').value,
            publisher: document.getElementById('editPublisher').value,
            publishedDate: document.getElementById('editPublishedDate').value,
            pages: document.getElementById('editPages').value,
            thumbnail: document.getElementById('editThumbnail').value,
            description: document.getElementById('editDescription').value
        };

        if (!bookData.isbn) {
            alert('ISBN is required');
            return;
        }

        try {
            const response = await fetch(`${config.API_URL}/book`, {
                method: 'POST',
                credentials: 'include',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(bookData)
            });

            if (response.ok) {
                alert('Book added successfully!');
                window.location.href = 'library.html';
            } else {
                const error = await response.json();
                throw new Error(error.message || 'Failed to add book');
            }
        } catch (error) {
            console.error('Error:', error);
            alert(error.message);
        }
    });

    // Cancel button handler
    cancelBtn.addEventListener('click', () => {
        window.location.href = 'library.html';
    });

    // Update page title and header for add mode
    document.querySelector('h1').textContent = '📖 Add New Book';
    document.getElementById('formTitle').textContent = 'Add New Book';
});