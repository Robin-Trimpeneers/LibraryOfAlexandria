import config from './config.js';

document.addEventListener('DOMContentLoaded', async () => {
     preventAccessWithoutCookie();


      function preventAccessWithoutCookie() {
        fetch(`${config.API_URL}/api/auth/check-cookie`, { credentials: 'include' })            .then(response => response.json())
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
    const isbn = urlParams.get('isbn');

    if (!isbn) {
        alert('ISBN parameter is missing');
        window.location.href = '/';
        return;
    }

    document.getElementById('addToLibraryBtn').addEventListener('click', async () => {
        try {
            const response = await fetch(`${config.API_URL}/book/${isbn}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                credentials: 'include'
            });

            if (response.ok) {
                alert('Book added to your library successfully!');
                window.location.href = '/library.html';
            } else {
                const errorData = await response.text();
                throw new Error(errorData || 'Failed to add book to library');
            }
        } catch (error) {
            console.error('Add to library error:', error);
            alert(`Error: ${error.message}`);
        }
    });

    try {
        const response = await fetch(`${config.API_URL}/book/${isbn}`, {
            method: 'GET',
            credentials: 'include',
            headers: { 'Content-Type': 'application/json' }
        });

        if (!response.ok) {
            const errorData = await response.text();
            throw new Error(errorData || 'Failed to fetch book');
        }

        const book = await response.json();
        populateBookDetails(book);

    } catch (error) {
        console.error('Error:', error);
        alert(`Error: ${error.message}`);
        window.location.href = '/';
    }
});

function populateBookDetails(book) {
    document.getElementById('bookTitle').textContent = book.title || 'Unknown Title';
    document.getElementById('bookAuthor').textContent = `by ${book.author || 'Unknown Author'}`;
    document.getElementById('bookIsbn').textContent = book.isbn;
    document.getElementById('bookGenre').textContent = book.genre || 'Not specified';
    document.getElementById('bookPages').textContent = book.pages ? `${book.pages} pages` : 'Page count unknown';
    document.getElementById('bookPublisher').textContent = book.publisher || 'Unknown publisher';
    document.getElementById('bookPublishedDate').textContent = book.publishedDate || 'Unknown date';
    document.getElementById('bookLanguage').textContent = book.language ? book.language.toUpperCase() : 'N/A';
    document.getElementById('bookOwner').textContent = book.ownerId === -1 ? 'Not owned yet' : 'Owned';
    document.getElementById('bookDescription').textContent = book.description || 'No description available';

    if (book.thumbnail) {
        document.getElementById('bookThumbnail').src = book.thumbnail;
    }
}