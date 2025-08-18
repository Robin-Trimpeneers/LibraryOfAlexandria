import config from './config.js';

document.addEventListener("DOMContentLoaded", () => {
    const searchForm = document.getElementById('search-form');
    const booksContainer = document.getElementById('booksContainer');
    const addBookForm = document.getElementById('addBookForm');
    const addIsbn = document.getElementById('addIsbn');
    const categoryFilter = document.getElementById('categoryFilter');

    fetchCategories();
    preventAccessWithoutCookie();
    fetchUserBooks();

    categoryFilter.addEventListener('change', (e) => {
        const selectedCategory = e.target.value;
        if (selectedCategory) {
            fetchBooksByCategory(selectedCategory);
        } else {
            fetchUserBooks();
        }
    });

    async function preventAccessWithoutCookie() {
        fetch(`${config.API_URL}/api/auth/check-cookie`, { credentials: 'include' })
            .then(response => response.json())
            .then(data => {
                console.log(data.message);
                if (data.message !== "Cookie found") {
                    window.location.href = '/login.html';
                }
            })
            .catch(error => {
                console.error('Error checking cookie:', error);
                window.location.href = '/login.html';
            });
    }
    async function fetchBooksByCategory(category) {
        try {
            const response = await fetch(`${config.API_URL}/book/category/${category}`, {
                method: 'GET',
                credentials: 'include',
                headers: { 'Content-Type': 'application/json' }
            });

            if (response.ok) {
                const books = await response.json();
                displayBooks(books);
            } else {
                throw new Error('Failed to fetch books by category');
            }
        } catch (error) {
            console.error('Error fetching books by category:', error);
            showTempMessage('Failed to load books by category', 'danger');
        }
    }

    async function fetchUserBooks() {
        try {
            const response = await fetch(`${config.API_URL}/book`, {
                method: 'GET',
                credentials: 'include',
                headers: { 'Content-Type': 'application/json' }
            });

            if (response.ok) {
                const books = await response.json();
                displayBooks(books);
            } else {
                throw new Error('Failed to fetch books');
            }
        } catch (error) {
            console.error('Error fetching books:', error);
            showTempMessage('Failed to load books', 'danger');
        }
    }
    async function deleteBook(isbn) {
        try {
            const response = await fetch(`${config.API_URL}/book/${isbn}`, {
                method: 'DELETE',
                credentials: 'include',
                headers: { 'Content-Type': 'application/json' }
            });

            if (response.ok) {
                alert('Book removed successfully!');
                location.reload();
            } else {
                throw new Error('Failed to delete book');
            }
        } catch (error) {
            console.error('Error deleting book:', error);
            showTempMessage('Failed to delete book', 'danger');
        }
    }

    function displayBooks(books) {
        booksContainer.innerHTML = '';

        if (books.length === 0) {
            const noBooksMessage = document.createElement('div');
            noBooksMessage.className = 'alert alert-info text-center';
            noBooksMessage.textContent = 'No books yet';
            booksContainer.appendChild(noBooksMessage);
            return;
        }

        const row = document.createElement('div');
        row.className = 'row';

        books.forEach(book => {
            const col = document.createElement('div');
            col.className = 'col-md-3 mb-3';
            col.innerHTML = `
                <div class="card h-100" data-book='${JSON.stringify(book)}'>
                    <button class="delete-button" title="Delete">×</button>
                    <img src="${book.thumbnail || config.DEFAULT_BOOK_COVER}" class="card-img-top" alt="${book.title}" style="height: 200px; object-fit: cover;">
                    <div class="card-body">
                        <h5 class="card-title">${book.title}</h5>
                        <p class="card-text">${book.author}</p>
                    </div>
                </div>
            `;
            col.querySelector('.delete-button').addEventListener('click', (e) => {
                e.stopPropagation();
                if (confirm('Are you sure you want to delete this book?')) {
                    deleteBook(book.isbn);
                }
            });
            col.addEventListener('click', () => {
                sessionStorage.setItem('selectedBook', JSON.stringify(book));
                window.location.href = 'ownedDetails.html';
            });
            row.appendChild(col);
        });

        booksContainer.appendChild(row);
    }

    addBookForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        if (!addIsbn.value) {
            showTempMessage('Please enter an ISBN to add', 'warning');
            return;
        }
        try {
            const response = await fetch(`${config.API_URL}/book/${addIsbn.value}`, {
                method: 'POST',
                credentials: 'include',
                headers: { 'Content-Type': 'application/json' }
            });

            if (response.ok) {
                alert("Book added successfully");
                location.reload();
            } else {
                const error = await response.json();
                showTempMessage(`Error: ${error.message}`, 'danger');
            }
        } catch (error) {
            console.error('Add book error:', error);
            showTempMessage('Failed to add book', 'danger');
        }
    });

    searchForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        console.log("Search button clicked");

        const isbn = document.getElementById('isbnSearch').value.trim();
        if (!isbn) {
            showTempMessage('Please enter an ISBN to search', 'warning');
            return;
        }

        try {
            const response = await fetch(`${config.API_URL}/book/${isbn}`, {
                method: 'GET',
                credentials: 'include',
                headers: { 'Content-Type': 'application/json' }
            });

            if (response.ok) {
                window.location.href = `details.html?isbn=${encodeURIComponent(isbn)}`;
            } else {
                const error = await response.json();
                showTempMessage(`Error: ${error.message}`, 'danger');
            }
        } catch (error) {
            console.error('Search error:', error);
            showTempMessage('Failed to search for book', 'danger');
        }
    });

    async function fetchCategories() {
        try {
            const response = await fetch(`${config.API_URL}/book/categories`, {
                method: 'GET',
                credentials: 'include',
                headers: { 'Content-Type': 'application/json' }
            });

            if (!response.ok) throw new Error('Failed to fetch categories');
            const categories = await response.json();
            const categoryFilter = document.getElementById('categoryFilter');

            categoryFilter.innerHTML = '<option value="">All Categories</option>';
            categories.forEach(category => {
                const option = document.createElement('option');
                option.value = category;
                option.textContent = category;
                categoryFilter.appendChild(option);
            });
        } catch (error) {
            console.error('Fetch categories error:', error);
            showTempMessage('Failed to load categories', 'danger');
        }
    }

    function showTempMessage(message, type) {
        const messageBox = document.createElement('div');
        messageBox.className = `alert alert-${type}`;
        messageBox.textContent = message;
        document.body.appendChild(messageBox);
        setTimeout(() => {
            document.body.removeChild(messageBox);
        }, config.NOTIFICATION_DURATION);
    }
});