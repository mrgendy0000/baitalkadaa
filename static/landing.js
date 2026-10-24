// Accessible marketing navigation. Motion is provided by launch.js with reduced-motion support.
(() => {
 const header=document.querySelector('.odoo-main-nav'),menu=document.querySelector('.nav-menu-toggle');
 const close=()=>{header?.classList.remove('menu-open');menu?.setAttribute('aria-expanded','false');};
 menu?.addEventListener('click',()=>{const open=header?.classList.toggle('menu-open');menu.setAttribute('aria-expanded',String(!!open));});
 document.querySelectorAll('.odoo-nav-link').forEach(link=>link.addEventListener('click',()=>{document.querySelectorAll('.odoo-nav-link').forEach(i=>i.classList.remove('active'));link.classList.add('active');close();}));
 document.addEventListener('keydown',event=>{if(event.key==='Escape')close();});
 document.querySelectorAll('.odoo-app-card').forEach(card=>{card.setAttribute('role','button');card.tabIndex=0;card.addEventListener('keydown',event=>{if(['Enter',' '].includes(event.key)){event.preventDefault();card.click();}});});
})();
