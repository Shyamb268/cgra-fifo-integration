document.addEventListener('DOMContentLoaded', () => {
    // Smooth scrolling for navigation links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Active navigation link highlighting
    const sections = document.querySelectorAll('section');
    const navLinks = document.querySelectorAll('.nav-links a');

    window.addEventListener('scroll', () => {
        let current = '';
        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.clientHeight;
            if (pageYOffset >= sectionTop - 200) {
                current = section.getAttribute('id');
            }
        });

        navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href').slice(1) === current) {
                link.classList.add('active');
            }
        });
    });

    // Add animation to cards on scroll
    const cards = document.querySelectorAll('.card, .project-card, .tech-card');
    const observerOptions = {
        threshold: 0.1
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    cards.forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(20px)';
        card.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
        observer.observe(card);
    });

    // Update dashboard stats with animation
    const stats = document.querySelectorAll('.stat');
    stats.forEach(stat => {
        const target = parseInt(stat.textContent);
        let current = 0;
        const increment = target / 50;
        const updateStat = () => {
            if (current < target) {
                current += increment;
                stat.textContent = Math.ceil(current);
                requestAnimationFrame(updateStat);
            } else {
                stat.textContent = target;
            }
        };
        updateStat();
    });

    // File Upload and Project Management
    const projectUploadForm = document.getElementById('projectUploadForm');
    const fileInput = document.getElementById('projectFiles');
    const fileList = document.getElementById('fileList');
    const projectsGrid = document.getElementById('projectsGrid');

    // Store projects in localStorage
    let projects = JSON.parse(localStorage.getItem('projects')) || [];

    // Display existing projects
    function displayProjects() {
        projectsGrid.innerHTML = '';
        projects.forEach((project, index) => {
            const projectElement = createProjectElement(project, index);
            projectsGrid.appendChild(projectElement);
        });
    }

    // Create project element
    function createProjectElement(project, index) {
        const div = document.createElement('div');
        div.className = 'project-item';
        div.innerHTML = `
            <h4>${project.title}</h4>
            <div class="date">${project.date}</div>
            <div class="description">${project.description}</div>
            <div class="project-files">
                ${project.files.map(file => `
                    <span class="file-tag">
                        <i class="fas fa-file"></i>
                        ${file.name}
                    </span>
                `).join('')}
            </div>
            <button class="delete-btn" onclick="deleteProject(${index})">Delete Project</button>
        `;
        return div;
    }

    // Handle file selection
    fileInput.addEventListener('change', () => {
        fileList.innerHTML = '';
        Array.from(fileInput.files).forEach(file => {
            const fileItem = document.createElement('div');
            fileItem.textContent = `${file.name} (${formatFileSize(file.size)})`;
            fileList.appendChild(fileItem);
        });
    });

    // Format file size
    function formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    // Handle form submission
    projectUploadForm.addEventListener('submit', (e) => {
        e.preventDefault();

        const project = {
            title: document.getElementById('projectTitle').value,
            description: document.getElementById('projectDescription').value,
            date: document.getElementById('projectDate').value,
            files: Array.from(fileInput.files).map(file => ({
                name: file.name,
                size: file.size,
                type: file.type
            }))
        };

        projects.unshift(project);
        localStorage.setItem('projects', JSON.stringify(projects));
        displayProjects();

        // Reset form
        projectUploadForm.reset();
        fileList.innerHTML = '';
    });

    // Delete project
    window.deleteProject = function(index) {
        if (confirm('Are you sure you want to delete this project?')) {
            projects.splice(index, 1);
            localStorage.setItem('projects', JSON.stringify(projects));
            displayProjects();
        }
    };

    // Initial display of projects
    displayProjects();
}); 