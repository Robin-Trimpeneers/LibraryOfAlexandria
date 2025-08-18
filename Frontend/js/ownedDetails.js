import config from './config.js';

document.addEventListener('DOMContentLoaded', () => {
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
    
    try {
        // Retrieve the selected book from sessionStorage
        const book = JSON.parse(sessionStorage.getItem('selectedBook'));

        if (!book) {
            alert('No book data found in sessionStorage');
            window.location.href = '/';  // Redirect to homepage or library page
            return;
        }

        // Populate the book details on the page
        populateBookDetails(book);
    } catch (error) {
        console.error('Error loading book details:', error);
        alert('Failed to load book details. Please try again.');
        window.location.href = '/';  // Redirect to homepage or library page
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