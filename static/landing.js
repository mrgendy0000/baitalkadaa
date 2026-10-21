// Responsive navigation and keyboard access for existing marketing previews.
const marketingHeader = document.querySelector('.odoo-main-nav');
const marketingMenu = document.querySelector('.nav-menu-toggle');
function closeMarketingMenu() {
    marketingHeader.classList.remove('menu-open');
    marketingMenu.setAttribute('aria-expanded', 'false');
}
marketingMenu.addEventListener('click', () => {
    const expanded = marketingHeader.classList.toggle('menu-open');
    marketingMenu.setAttribute('aria-expanded', String(expanded));
});
document.querySelectorAll('.odoo-nav-link').forEach(link => {
    link.addEventListener('click', () => {
        document.querySelectorAll('.odoo-nav-link').forEach(item => item.classList.remove('active'));
        link.classList.add('active');
        closeMarketingMenu();
    });
});
document.addEventListener('keydown', event => {
    if (event.key === 'Escape') {
        closeMarketingMenu();
        document.querySelectorAll('.modal-backdrop').forEach(modal => modal.style.display = 'none');
    }
});
document.querySelectorAll('.odoo-app-card').forEach(card => {
    card.setAttribute('role', 'button');
    card.setAttribute('tabindex', '0');
    card.addEventListener('keydown', event => {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            card.click();
        }
    });
    card.addEventListener('click', () => {
        document.querySelectorAll('.odoo-app-card').forEach(item => item.classList.remove('active'));
        card.classList.add('active');
    });
});

// Animate complete Arabic phrases; never split joined letters or change layout height.
const motionPreference = window.matchMedia('(prefers-reduced-motion: reduce)');
const motionControl = document.querySelector('.hero-motion-toggle');
const heroPhrases = [...document.querySelectorAll('.hero-phrase')];
let motionPaused = false;
let heroVisible = false;
let phraseIndex = 0;
let phraseTimer;
function updateHeroMotion() {
    clearInterval(phraseTimer);
    const paused = motionPaused || motionPreference.matches;
    document.documentElement.dataset.motion = paused ? 'paused' : 'active';
    motionControl.setAttribute('aria-pressed', String(motionPaused));
    motionControl.setAttribute('aria-label', motionPaused ? 'تشغيل حركة الواجهة' : 'إيقاف حركة الواجهة');
    motionControl.querySelector('span').textContent = motionPaused ? 'تشغيل الحركة' : 'إيقاف الحركة';
    if (paused || !heroVisible || document.hidden) return;
    phraseTimer = setInterval(() => {
        heroPhrases.forEach(phrase => phrase.classList.remove('is-leaving'));
        heroPhrases[phraseIndex].classList.replace('is-current', 'is-leaving');
        phraseIndex = (phraseIndex + 1) % heroPhrases.length;
        heroPhrases[phraseIndex].classList.add('is-current');
    }, 4200);
}
motionControl.addEventListener('click', () => {
    motionPaused = !motionPaused;
    updateHeroMotion();
});
motionPreference.addEventListener('change', updateHeroMotion);
document.addEventListener('visibilitychange', updateHeroMotion);
const heroObserver = new IntersectionObserver(entries => {
    heroVisible = entries[0].isIntersecting;
    updateHeroMotion();
}, { threshold: 0.1 });
heroObserver.observe(document.querySelector('.hx-hero'));
updateHeroMotion();
