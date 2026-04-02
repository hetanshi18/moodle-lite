// ── Auto-dismiss flash messages ─────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  const alerts = document.querySelectorAll('.flash-alert');
  alerts.forEach(alert => {
    setTimeout(() => {
      const bsAlert = bootstrap.Alert.getOrCreateInstance(alert);
      bsAlert.close();
    }, 5000);
  });

  // ── Animate cards on page load ──────────────────────────
  const cards = document.querySelectorAll('.course-card, .ml-card, .stat-tile');
  cards.forEach((card, i) => {
    card.style.opacity = '0';
    card.style.transform = 'translateY(20px)';
    setTimeout(() => {
      card.style.transition = 'opacity 0.4s ease, transform 0.4s ease';
      card.style.opacity = '1';
      card.style.transform = 'translateY(0)';
    }, 60 * i);
  });

  // ── Upload zone drag-and-drop highlight ─────────────────
  const zones = document.querySelectorAll('.upload-zone');
  zones.forEach(zone => {
    zone.addEventListener('dragover', e => {
      e.preventDefault();
      zone.classList.add('drag-over');
    });
    zone.addEventListener('dragleave', () => zone.classList.remove('drag-over'));
    zone.addEventListener('drop', e => {
      e.preventDefault();
      zone.classList.remove('drag-over');
      const input = zone.querySelector('input[type="file"]');
      if (input && e.dataTransfer.files.length > 0) {
        input.files = e.dataTransfer.files;
        const label = zone.querySelector('.upload-filename');
        if (label) label.textContent = e.dataTransfer.files[0].name;
      }
    });
  });

  // ── File input filename display ─────────────────────────
  const fileInputs = document.querySelectorAll('input[type="file"]');
  fileInputs.forEach(input => {
    input.addEventListener('change', () => {
      const label = document.querySelector(`[data-for="${input.id}"]`) ||
                    input.closest('.upload-zone')?.querySelector('.upload-filename');
      if (label && input.files.length > 0) {
        label.textContent = input.files[0].name;
      }
    });
  });
});
