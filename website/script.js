// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        document.querySelector(this.getAttribute('href')).scrollIntoView({
            behavior: 'smooth'
        });
    });
});

// Intersection Observer for fade-in animations
const observerOptions = {
    root: null,
    rootMargin: '0px',
    threshold: 0.1
};

const observer = new IntersectionObserver((entries, observer) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
            observer.unobserve(entry.target);
        }
    });
}, observerOptions);

// Observe all sections
document.querySelectorAll('.section').forEach(section => {
    section.style.opacity = '0';
    section.style.transform = 'translateY(20px)';
    observer.observe(section);
});

// Code highlighting initialization
document.addEventListener('DOMContentLoaded', () => {
    if (typeof Prism !== 'undefined') {
        Prism.highlightAll();
    }
});

// Card flip functionality
document.querySelectorAll('.card').forEach(card => {
    card.addEventListener('click', () => {
        card.querySelector('.card-inner').style.transform = 
            card.querySelector('.card-inner').style.transform === 'rotateY(180deg)' 
                ? 'rotateY(0deg)' 
                : 'rotateY(180deg)';
    });
});

// Responsive navigation
const navToggle = document.createElement('button');
navToggle.className = 'nav-toggle';
navToggle.innerHTML = '☰';
document.querySelector('.nav-content').prepend(navToggle);

navToggle.addEventListener('click', () => {
    document.querySelector('.nav-links').classList.toggle('show');
}); 