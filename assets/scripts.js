document.addEventListener("DOMContentLoaded", () => {
    const anoEl = document.getElementById('ano-atual');
    if (anoEl) anoEl.textContent = new Date().getFullYear();

    /* ---------- Mobile navigation (off-canvas drawer) ---------- */
    const header = document.querySelector('header');
    const navToggle = document.querySelector('.nav-toggle');
    const navPanel = document.getElementById('site-nav');
    const backdrop = document.querySelector('.nav-backdrop');

    if (header && navToggle && navPanel) {
        if (backdrop) backdrop.removeAttribute('hidden');

        const getFocusable = () => [
            navToggle,
            ...navPanel.querySelectorAll('a[href], button:not([disabled])')
        ];

        const openMenu = () => {
            header.classList.add('nav-open');
            navToggle.setAttribute('aria-expanded', 'true');
            navToggle.setAttribute('aria-label', 'Fechar menu');
            document.body.style.overflow = 'hidden';
            const firstLink = navPanel.querySelector('nav.primary a');
            if (firstLink) firstLink.focus();
        };

        const closeMenu = ({ focusToggle = false } = {}) => {
            header.classList.remove('nav-open');
            navToggle.setAttribute('aria-expanded', 'false');
            navToggle.setAttribute('aria-label', 'Abrir menu');
            document.body.style.overflow = '';
            if (focusToggle) navToggle.focus();
        };

        navToggle.addEventListener('click', () => {
            if (header.classList.contains('nav-open')) {
                closeMenu();
            } else {
                openMenu();
            }
        });

        if (backdrop) {
            backdrop.addEventListener('click', () => closeMenu());
        }

        // Close after picking a destination
        navPanel.querySelectorAll('nav.primary a').forEach(link => {
            link.addEventListener('click', () => closeMenu());
        });

        // Close with the Escape key + trap focus inside the drawer
        document.addEventListener('keydown', (e) => {
            if (!header.classList.contains('nav-open')) return;

            if (e.key === 'Escape') {
                closeMenu({ focusToggle: true });
                return;
            }

            if (e.key === 'Tab') {
                const focusable = getFocusable();
                const first = focusable[0];
                const last = focusable[focusable.length - 1];
                if (e.shiftKey && document.activeElement === first) {
                    e.preventDefault();
                    last.focus();
                } else if (!e.shiftKey && document.activeElement === last) {
                    e.preventDefault();
                    first.focus();
                }
            }
        });

        // Reset when resizing back up to the desktop layout
        const desktopQuery = window.matchMedia('(min-width: 901px)');
        desktopQuery.addEventListener('change', (e) => {
            if (e.matches) closeMenu();
        });
    }

    const reveals = document.querySelectorAll('.reveal');
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    if (prefersReducedMotion || !('IntersectionObserver' in window)) {
        reveals.forEach(el => el.classList.add('active'));
        return;
    }

    const revealOnScroll = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('active');
                observer.unobserve(entry.target);
            }
        });
    }, {
        threshold: 0.1,
        rootMargin: "0px 0px -50px 0px"
    });

    reveals.forEach(reveal => revealOnScroll.observe(reveal));
});
