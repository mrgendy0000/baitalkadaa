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
