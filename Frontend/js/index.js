document.addEventListener("DOMContentLoaded", () => {
    console.log("Clearing JWT token on page load...");

    // Remove JWT from localStorage
    localStorage.removeItem('jwt');

    // Remove JWT from cookies
    document.cookie = "JWT=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    

    console.log("JWT token cleared.");
});
