// ============================
// FastTracker PWA — app.js
// ============================

// ---------- PHYSIOLOGICAL EVENTS ----------
const EVENTS = [
  { hour: 0, title: "Fast Begins", desc: "Your body begins using readily available glucose from your last meal. Insulin levels start to drop.", icon: "🏁", cat: "metabolic", quote: "Every journey begins with a single step. You've got this!" },
  { hour: 4, title: "Blood Sugar Stabilizes", desc: "Post-meal insulin spike subsides. Blood glucose levels begin normalizing.", icon: "📉", cat: "hormonal", quote: "Your body is already starting to adjust. Stay strong!" },
  { hour: 8, title: "Glycogen Depletion Begins", desc: "Your liver begins tapping into stored glycogen (sugar reserves). This is your body's first fuel switch.", icon: "⚡", cat: "metabolic", quote: "Your body is switching gears — burning through stored sugar now." },
  { hour: 12, title: "Entering Early Ketosis", desc: "Glycogen stores running low. Your liver starts converting fatty acids into ketone bodies. Growth hormone begins to rise.", icon: "🔥", cat: "metabolic", quote: "Welcome to fat-burning mode! Your metabolism is shifting." },
  { hour: 14, title: "Growth Hormone Surge", desc: "HGH levels begin increasing significantly, promoting fat burning and muscle preservation.", icon: "📈", cat: "hormonal", quote: "HGH is rising — your body is protecting muscle while burning fat!" },
  { hour: 16, title: "Autophagy Initiates", desc: "Your cells begin 'self-cleaning' — recycling damaged proteins and components. Cellular housekeeping at its finest.", icon: "♻️", cat: "cellular", quote: "Autophagy is online! Your cells are literally cleaning house." },
  { hour: 18, title: "Fat Burning Accelerates", desc: "Your body is now primarily burning fat for fuel. Ketone levels continue to rise, providing clean energy to your brain.", icon: "🔥", cat: "metabolic", quote: "You're a fat-burning machine now. Keep pushing!" },
  { hour: 24, title: "Day 1 Complete — Full Ketosis", desc: "Glycogen is mostly depleted. Ketones are now a significant energy source. Insulin at baseline. Inflammation markers decrease.", icon: "1️⃣", cat: "metabolic", quote: "Day 1 done! You've crossed into deep metabolic territory. Amazing!" },
  { hour: 24, title: "Anti-Inflammatory Response", desc: "Pro-inflammatory cytokines begin decreasing. Your body starts to reduce systemic inflammation.", icon: "🛡️", cat: "immune", quote: "Your immune system is recalibrating. Inflammation is dropping." },
  { hour: 36, title: "Deep Autophagy", desc: "Autophagy is now in full effect. Damaged mitochondria and misfolded proteins are being aggressively recycled.", icon: "✨", cat: "cellular", quote: "Deep cellular repair is happening right now. You're renewing from within!" },
  { hour: 48, title: "Day 2 Complete — HGH Peak", desc: "HGH can be up to 5x baseline levels. Ketone-fueled brain clarity often peaks around this time. BDNF increases.", icon: "2️⃣", cat: "hormonal", quote: "Day 2 conquered! HGH is surging and your brain is getting sharper." },
  { hour: 48, title: "BDNF Increases", desc: "Brain-Derived Neurotrophic Factor rises, supporting neuron growth, learning, and memory. Many report enhanced mental clarity.", icon: "🧠", cat: "neurological", quote: "Your brain is growing new connections. Mental clarity is your reward!" },
  { hour: 54, title: "Electrolyte Awareness", desc: "Pay attention to sodium, potassium, and magnesium. Supplementing electrolytes becomes important for wellbeing.", icon: "💧", cat: "metabolic", quote: "Stay on top of electrolytes — they're your best friend right now." },
  { hour: 60, title: "Hunger Hormones Subside", desc: "Ghrelin (the hunger hormone) starts to decrease. Many fasters report that hunger pangs become less intense.", icon: "⬇️", cat: "hormonal", quote: "Hunger is fading! Your body has adapted to burning its own fuel." },
  { hour: 72, title: "Day 3 Complete — Immune Reset", desc: "Research suggests immune system regeneration begins. Old white blood cells are broken down, triggering stem cell renewal.", icon: "3️⃣", cat: "immune", quote: "Day 3 done! Your immune system is regenerating. You're incredible!" },
  { hour: 72, title: "Stem Cell Activation", desc: "Hematopoietic stem cells shift toward self-renewal. Your body begins building a fresher, more efficient immune system.", icon: "🌱", cat: "cellular", quote: "Stem cells are waking up. Renewal at the deepest level!" },
  { hour: 84, title: "Ketone Adaptation", desc: "Your brain is now highly efficient at using ketones. Many report euphoria, extreme mental clarity, and sustained energy.", icon: "🧠", cat: "neurological", quote: "Your brain is fully keto-adapted. Ride the clarity wave!" },
  { hour: 96, title: "Day 4 Complete — Deep Renewal", desc: "Autophagy at advanced levels. Damaged components significantly cleared. Insulin sensitivity greatly improved.", icon: "4️⃣", cat: "cellular", quote: "Day 4 down! You're in rare territory. Your body is thanking you." },
  { hour: 96, title: "Insulin Sensitivity Restored", desc: "Your cells have become highly sensitive to insulin again. This helps with glucose regulation long after the fast ends.", icon: "💚", cat: "hormonal", quote: "Your metabolic health is resetting. This benefit lasts well beyond the fast!" },
  { hour: 108, title: "Peak Autophagy & Immune Renewal", desc: "Cellular cleanup at maximum. Immune system significantly refreshed with new white blood cells.", icon: "⭐", cat: "immune", quote: "You're at the summit! Peak cellular renewal is happening right now." },
  { hour: 120, title: "Day 5 Complete — Fast Finished!", desc: "Congratulations! You've completed a 5-day fast. Significant metabolic, cellular, and immune renewal. Refeed slowly and mindfully.", icon: "🏆", cat: "metabolic", quote: "YOU DID IT! 5 days of incredible transformation. Be proud — you're a champion!" },
];

const CAT_COLORS = {
  metabolic: 'orange',
  cellular: 'green',
  hormonal: 'purple',
  neurological: 'blue',
  immune: 'red',
};

// ---------- STATE ----------
let state = null; // { startTime, durationDays, weightKg, heightCm, age, isMale, activityMult }
let timerInterval = null;
let currentFilter = 'all';

// ---------- HELPERS ----------
function $(sel) { return document.querySelector(sel); }
function $$(sel) { return document.querySelectorAll(sel); }

function bmr(w, h, age, male) {
  return male ? (10 * w) + (6.25 * h) - (5 * age) + 5
               : (10 * w) + (6.25 * h) - (5 * age) - 161;
}

function tdee(w, h, age, male, mult) {
  return bmr(w, h, age, male) * mult;
}

function caloriesBurned(s, elapsedH) {
  const daily = tdee(s.weightKg, s.heightCm, s.age, s.isMale, s.activityMult);
  const days = elapsedH / 24;
  let adj = 1.0;
  if (days > 3) adj = 0.90;
  else if (days > 2) adj = 0.93;
  else if (days > 1) adj = 0.97;
  return (daily * adj * elapsedH) / 24;
}

function weightLossKg(s, elapsedH) {
  const days = elapsedH / 24;
  const water = days <= 2 ? Math.min(days * 0.8, 1.6) : 1.6;
  const fat = caloriesBurned(s, elapsedH) / 7700;
  return water + fat;
}

function fuelSources(h) {
  if (h < 8)  return { glucose: 70, fat: 25, ketones: 5 };
  if (h < 16) return { glucose: 40, fat: 45, ketones: 15 };
  if (h < 24) return { glucose: 15, fat: 50, ketones: 35 };
  if (h < 48) return { glucose: 5, fat: 45, ketones: 50 };
  return { glucose: 3, fat: 37, ketones: 60 };
}

function phase(h) {
  if (h < 8) return 'Fed State';
  if (h < 12) return 'Early Fasting';
  if (h < 18) return 'Glycogen Depletion';
  if (h < 24) return 'Early Ketosis';
  if (h < 48) return 'Ketosis';
  if (h < 72) return 'Deep Ketosis';
  if (h < 96) return 'Immune Renewal';
  return 'Extended Fast';
}

function ketoneLevel(h) {
  if (h < 12) return 0.1;
  if (h < 24) return 0.5;
  if (h < 48) return 1.5;
  if (h < 72) return 3.0;
  if (h < 96) return 4.0;
  return 5.0;
}

function ketoneLabel(lvl) {
  if (lvl < 0.5) return 'Not in ketosis';
  if (lvl < 1.0) return 'Light ketosis';
  if (lvl < 3.0) return 'Moderate ketosis';
  return 'Deep ketosis';
}

function fmtDuration(sec) {
  const d = Math.floor(sec / 86400);
  const h = Math.floor((sec % 86400) / 3600);
  const m = Math.floor((sec % 3600) / 60);
  const s = Math.floor(sec % 60);
  if (d > 0) return `${d}d ${pad(h)}h ${pad(m)}m ${pad(s)}s`;
  if (h > 0) return `${h}h ${pad(m)}m ${pad(s)}s`;
  return `${m}m ${pad(s)}s`;
}

function fmtRemaining(sec) {
  const d = Math.floor(sec / 86400);
  const h = Math.floor((sec % 86400) / 3600);
  const m = Math.floor((sec % 3600) / 60);
  if (d > 0) return `${d}d ${h}h ${m}m`;
  if (h > 0) return `${h}h ${m}m`;
  return `${m}m`;
}

function pad(n) { return String(n).padStart(2, '0'); }

function fmtDate(d) {
  return d.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' });
}

// ---------- PERSISTENCE ----------
function saveState() {
  if (state) localStorage.setItem('fasttracker_state', JSON.stringify(state));
}

function loadState() {
  const raw = localStorage.getItem('fasttracker_state');
  if (raw) {
    state = JSON.parse(raw);
    return true;
  }
  return false;
}

function clearState() {
  state = null;
  localStorage.removeItem('fasttracker_state');
}

// ---------- SVG GRADIENT (inject once) ----------
function injectRingGradient() {
  const svg = $('.progress-ring');
  if (!svg) return;
  const defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');
  const grad = document.createElementNS('http://www.w3.org/2000/svg', 'linearGradient');
  grad.setAttribute('id', 'ring-gradient');
  grad.setAttribute('x1', '0%'); grad.setAttribute('y1', '0%');
  grad.setAttribute('x2', '100%'); grad.setAttribute('y2', '100%');
  const stops = [
    { offset: '0%', color: '#3b82f6' },
    { offset: '33%', color: '#a855f7' },
    { offset: '66%', color: '#f97316' },
    { offset: '100%', color: '#ef4444' },
  ];
  stops.forEach(s => {
    const stop = document.createElementNS('http://www.w3.org/2000/svg', 'stop');
    stop.setAttribute('offset', s.offset);
    stop.setAttribute('stop-color', s.color);
    grad.appendChild(stop);
  });
  defs.appendChild(grad);
  svg.prepend(defs);
}

// ---------- SETUP SCREEN LOGIC ----------
function initSetup() {
  const slider = $('#duration-slider');
  const chips = $$('.chip[data-days]');
  const actBtns = $$('.activity-btn');
  let useMetric = true;

  slider.addEventListener('input', () => {
    updateDuration(parseInt(slider.value));
  });

  chips.forEach(c => c.addEventListener('click', () => {
    const d = parseInt(c.dataset.days);
    slider.value = d;
    updateDuration(d);
  }));

  function updateDuration(d) {
    $('#duration-value').textContent = d;
    $('#duration-hours').textContent = `(${d * 24} Hours)`;
    chips.forEach(c => c.classList.toggle('active', parseInt(c.dataset.days) === d));
    updatePreview();
  }

  // Unit toggle
  $('#btn-metric').addEventListener('click', () => { useMetric = true; updateUnits(); });
  $('#btn-imperial').addEventListener('click', () => { useMetric = false; updateUnits(); });

  function updateUnits() {
    $('#btn-metric').classList.toggle('active', useMetric);
    $('#btn-imperial').classList.toggle('active', !useMetric);
    $('#weight-unit').textContent = useMetric ? 'kg' : 'lbs';
    $('#height-unit').textContent = useMetric ? 'cm' : 'in';
    $('#preview-weight-unit').textContent = useMetric ? 'kg loss' : 'lbs loss';
    updatePreview();
  }

  // Gender toggle
  $('#btn-male').addEventListener('click', () => {
    $('#btn-male').classList.add('active');
    $('#btn-female').classList.remove('active');
    updatePreview();
  });
  $('#btn-female').addEventListener('click', () => {
    $('#btn-female').classList.add('active');
    $('#btn-male').classList.remove('active');
    updatePreview();
  });

  // Activity
  actBtns.forEach(b => b.addEventListener('click', () => {
    actBtns.forEach(x => x.classList.remove('active'));
    b.classList.add('active');
    updatePreview();
  }));

  // Live preview
  ['weight-input', 'height-input', 'age-input'].forEach(id => {
    $(`#${id}`).addEventListener('input', updatePreview);
  });

  function getSetupValues() {
    const isMale = $('#btn-male').classList.contains('active');
    let w = parseFloat($('#weight-input').value) || 80;
    let h = parseFloat($('#height-input').value) || 175;
    if (!useMetric) { w *= 0.453592; h *= 2.54; }
    const age = parseInt($('#age-input').value) || 30;
    const mult = parseFloat($('.activity-btn.active')?.dataset.mult) || 1.2;
    const days = parseInt(slider.value);
    return { isMale, weightKg: w, heightCm: h, age, activityMult: mult, durationDays: days, useMetric };
  }

  function updatePreview() {
    const v = getSetupValues();
    const daily = tdee(v.weightKg, v.heightCm, v.age, v.isMale, v.activityMult);
    const total = daily * v.durationDays * 0.93;
    const wl = total / 7700 + 1.6;
    $('#preview-daily').textContent = Math.round(daily);
    $('#preview-total').textContent = Math.round(total);
    const displayWl = v.useMetric ? wl : wl * 2.20462;
    $('#preview-weight').textContent = displayWl.toFixed(1);
  }

  updatePreview();

  // START
  $('#start-btn').addEventListener('click', () => {
    const v = getSetupValues();
    state = {
      startTime: Date.now(),
      durationDays: v.durationDays,
      weightKg: v.weightKg,
      heightCm: v.heightCm,
      age: v.age,
      isMale: v.isMale,
      activityMult: v.activityMult,
    };
    saveState();
    requestNotificationPermission();
    scheduleNotifications();
    showApp();
  });
}

// ---------- APP SCREEN LOGIC ----------
function showApp() {
  $('#setup-screen').classList.remove('active');
  $('#app-screen').classList.add('active');
  startTick();
  buildTimeline();
}

function showSetup() {
  $('#app-screen').classList.remove('active');
  $('#setup-screen').classList.add('active');
  if (timerInterval) { clearInterval(timerInterval); timerInterval = null; }
}

function startTick() {
  tick(); // immediate
  timerInterval = setInterval(tick, 1000);
}

const RING_CIRCUMFERENCE = 2 * Math.PI * 88; // ~553

function tick() {
  if (!state) return;

  const now = Date.now();
  const elapsedMs = now - state.startTime;
  const elapsedSec = elapsedMs / 1000;
  const elapsedH = elapsedSec / 3600;
  const totalSec = state.durationDays * 24 * 3600;
  const pct = Math.min(elapsedSec / totalSec, 1);
  const remainSec = Math.max(totalSec - elapsedSec, 0);

  // Auto finish
  if (pct >= 1) {
    clearInterval(timerInterval);
    timerInterval = null;
  }

  // Ring
  const ring = $('#ring-progress');
  ring.setAttribute('stroke-dasharray', RING_CIRCUMFERENCE);
  ring.setAttribute('stroke-dashoffset', RING_CIRCUMFERENCE * (1 - pct));

  // Timer text
  $('#elapsed-time').textContent = fmtDuration(elapsedSec);
  $('#progress-pct').textContent = `${Math.floor(pct * 100)}%`;
  $('#remaining-time').textContent = fmtRemaining(remainSec);
  $('#end-date').textContent = fmtDate(new Date(state.startTime + totalSec * 1000));

  // Phase
  $('#current-phase').textContent = phase(elapsedH);
  $('#current-day').textContent = `Day ${Math.floor(elapsedH / 24) + 1}`;

  // Stats
  const cals = caloriesBurned(state, elapsedH);
  const wlKg = weightLossKg(state, elapsedH);
  const wlLbs = wlKg * 2.20462;
  const dailyRate = tdee(state.weightKg, state.heightCm, state.age, state.isMale, state.activityMult);

  $('#stat-calories').textContent = Math.round(cals).toLocaleString();
  $('#stat-weightkg').textContent = wlKg.toFixed(1);
  $('#stat-weightlbs').textContent = wlLbs.toFixed(1);
  $('#stat-daily').textContent = Math.round(dailyRate).toLocaleString();

  // Fuel sources
  const fuel = fuelSources(elapsedH);
  $('#fuel-glucose').style.width = fuel.glucose + '%';
  $('#fuel-fat').style.width = fuel.fat + '%';
  $('#fuel-ketones').style.width = fuel.ketones + '%';
  $('#fuel-glucose-pct').textContent = fuel.glucose + '%';
  $('#fuel-fat-pct').textContent = fuel.fat + '%';
  $('#fuel-ketones-pct').textContent = fuel.ketones + '%';

  // Next event
  const nextEvt = EVENTS.find(e => e.hour > Math.floor(elapsedH));
  if (nextEvt) {
    $('#next-event-card').style.display = '';
    const hoursUntil = nextEvt.hour - Math.floor(elapsedH);
    $('#next-event-eta').textContent = `in ~${hoursUntil}h`;
    $('#next-event-icon').textContent = nextEvt.icon;
    $('#next-event-title').textContent = nextEvt.title;
    $('#next-event-desc').textContent = nextEvt.desc;
  } else {
    $('#next-event-card').style.display = 'none';
  }

  // Update timeline dots
  updateTimelineDots(elapsedH);

  // Stats tab
  updateStatsTab(elapsedH, cals, wlKg, dailyRate);
}

// ---------- STATS TAB ----------
function updateStatsTab(elapsedH, cals, wlKg, dailyRate) {
  if (!state) return;

  $('#stats-start-weight').textContent = state.weightKg.toFixed(1);
  const currentW = Math.max(state.weightKg - wlKg, state.weightKg * 0.9);
  $('#stats-current-weight').textContent = currentW.toFixed(1);
  $('#stats-lost-weight').textContent = `-${wlKg.toFixed(1)}`;

  const days = elapsedH / 24;
  const waterLoss = days <= 2 ? Math.min(days * 0.8, 1.6) : 1.6;
  const fatLoss = Math.max(wlKg - waterLoss, 0);
  $('#stats-water-loss').textContent = `${waterLoss.toFixed(1)} kg`;
  $('#stats-fat-loss').textContent = `${fatLoss.toFixed(1)} kg`;

  $('#stats-total-cal').textContent = Math.round(cals).toLocaleString();
  $('#stats-daily-rate').textContent = Math.round(dailyRate).toLocaleString();
  $('#stats-hourly-rate').textContent = Math.round(dailyRate / 24);
  $('#stats-bmr').textContent = Math.round(bmr(state.weightKg, state.heightCm, state.age, state.isMale));

  // Daily breakdown
  const container = $('#stats-daily-breakdown');
  const totalDays = Math.min(Math.floor(elapsedH / 24) + 1, state.durationDays);
  let html = '';
  for (let d = 1; d <= totalDays; d++) {
    const startH = (d - 1) * 24;
    const endH = Math.min(d * 24, elapsedH);
    if (endH <= startH) continue;
    const dayCal = caloriesBurned(state, endH) - caloriesBurned(state, startH);
    const isCurrent = d === totalDays && elapsedH < d * 24;
    html += `<div class="stats-day-row">
      <span>Day ${d}${isCurrent ? '<span class="current-tag">(in progress)</span>' : ''}</span>
      <strong>${Math.round(dayCal).toLocaleString()} kcal</strong>
    </div>`;
  }
  container.innerHTML = html;

  // Metabolic
  const kl = ketoneLevel(elapsedH);
  $('#stats-ketones').textContent = `~${kl.toFixed(1)} mmol/L`;
  $('#stats-ketosis-level').textContent = ketoneLabel(kl);
  $('#stats-fat-grams').textContent = `~${Math.round(cals / 9)} g`;

  if (days > 3) $('#stats-metabolic-rate').textContent = '~90% baseline';
  else if (days > 2) $('#stats-metabolic-rate').textContent = '~93% baseline';
  else if (days > 1) $('#stats-metabolic-rate').textContent = '~97% baseline';
  else $('#stats-metabolic-rate').textContent = '~100% baseline';

  if (elapsedH < 14) $('#stats-hgh').textContent = '~1x baseline';
  else if (elapsedH < 24) $('#stats-hgh').textContent = '~2x baseline';
  else if (elapsedH < 48) $('#stats-hgh').textContent = '~3x baseline';
  else $('#stats-hgh').textContent = '~5x baseline';

  if (elapsedH < 8) $('#stats-insulin').textContent = 'Decreasing';
  else if (elapsedH < 24) $('#stats-insulin').textContent = 'Low';
  else $('#stats-insulin').textContent = 'Very low (baseline)';
}

// ---------- TIMELINE ----------
function buildTimeline() {
  const list = $('#timeline-list');
  const filtered = currentFilter === 'all' ? EVENTS : EVENTS.filter(e => e.cat === currentFilter);

  let html = '';
  filtered.forEach((evt, i) => {
    const isLast = i === filtered.length - 1;
    const timeLabel = evt.hour >= 24
      ? `Day ${Math.floor(evt.hour / 24)} (${evt.hour}h)`
      : `${evt.hour}h`;

    html += `
      <div class="timeline-item" data-hour="${evt.hour}" data-cat="${evt.cat}">
        <div class="timeline-track">
          <div class="timeline-dot ${evt.cat}" data-hour="${evt.hour}">✓</div>
          ${!isLast ? '<div class="timeline-line" data-hour="' + evt.hour + '"></div>' : ''}
        </div>
        <div class="timeline-content" data-hour="${evt.hour}">
          <span class="tl-time ${evt.cat}">${timeLabel}</span>
          <span class="tl-category">${evt.cat}</span>
          <div class="tl-title">${evt.icon} ${evt.title}</div>
          <div class="tl-desc">${evt.desc}</div>
          <div class="tl-quote" data-hour="${evt.hour}" style="display:none">${evt.quote}</div>
        </div>
      </div>`;
  });
  list.innerHTML = html;

  // Update completed count
  if (state) {
    const elapsedH = (Date.now() - state.startTime) / 3600000;
    updateTimelineDots(elapsedH);
  }
}

function updateTimelineDots(elapsedH) {
  const hour = Math.floor(elapsedH);
  const completedCount = EVENTS.filter(e => e.hour <= hour).length;
  const eventsCountEl = $('#events-count');
  if (eventsCountEl) eventsCountEl.textContent = `${completedCount}/${EVENTS.length}`;

  // Find the last completed event
  const lastCompleted = [...EVENTS].reverse().find(e => e.hour <= hour);

  $$('.timeline-dot').forEach(dot => {
    const h = parseInt(dot.dataset.hour);
    dot.classList.remove('completed', 'current');
    if (h <= hour) {
      dot.classList.add('completed');
    }
  });

  // Mark current (most recent completed)
  if (lastCompleted) {
    const currentDots = $$(`.timeline-dot[data-hour="${lastCompleted.hour}"]`);
    currentDots.forEach(d => {
      d.classList.add('current');
    });
  }

  $$('.timeline-line').forEach(line => {
    const h = parseInt(line.dataset.hour);
    line.classList.toggle('completed', h <= hour);
  });

  $$('.timeline-content').forEach(content => {
    const h = parseInt(content.dataset.hour);
    content.classList.remove('current', 'dimmed');
    if (lastCompleted && h === lastCompleted.hour) {
      content.classList.add('current');
    } else if (h > hour) {
      content.classList.add('dimmed');
    }
  });

  // Show quotes for completed events
  $$('.tl-quote').forEach(q => {
    const h = parseInt(q.dataset.hour);
    q.style.display = h <= hour ? '' : 'none';
  });
}

// ---------- TABS ----------
function initTabs() {
  $$('.tab').forEach(tab => {
    tab.addEventListener('click', () => {
      const target = tab.dataset.tab;
      $$('.tab').forEach(t => t.classList.toggle('active', t === tab));
      $$('.tab-content').forEach(tc => tc.classList.toggle('active', tc.id === `tab-${target}`));
    });
  });
}

// ---------- FILTERS ----------
function initFilters() {
  $('#filter-chips').addEventListener('click', e => {
    const chip = e.target.closest('.filter-chip');
    if (!chip) return;
    currentFilter = chip.dataset.filter;
    $$('.filter-chip').forEach(c => c.classList.toggle('active', c === chip));
    buildTimeline();
  });
}

// ---------- END FAST ----------
function initEndFast() {
  $('#end-fast-btn').addEventListener('click', () => {
    // Show confirmation
    const overlay = document.createElement('div');
    overlay.className = 'confirm-overlay';
    overlay.innerHTML = `
      <div class="confirm-box">
        <h3>End Fast?</h3>
        <p>Are you sure you want to end your fasting session?</p>
        <div class="confirm-actions">
          <button class="btn-cancel">Cancel</button>
          <button class="btn-confirm-end">End Fast</button>
        </div>
      </div>`;
    document.body.appendChild(overlay);

    overlay.querySelector('.btn-cancel').addEventListener('click', () => overlay.remove());
    overlay.querySelector('.btn-confirm-end').addEventListener('click', () => {
      overlay.remove();
      clearState();
      if (timerInterval) { clearInterval(timerInterval); timerInterval = null; }
      showSetup();
    });
  });
}

// ---------- EDIT TIMES ----------
function initEditTimes() {
  $('#edit-times-btn').addEventListener('click', () => {
    if (!state) return;

    const startDate = new Date(state.startTime);
    const endDate = new Date(state.startTime + state.durationDays * 24 * 3600 * 1000);

    const fmt = d => {
      const y = d.getFullYear();
      const mo = String(d.getMonth() + 1).padStart(2, '0');
      const da = String(d.getDate()).padStart(2, '0');
      const h = String(d.getHours()).padStart(2, '0');
      const mi = String(d.getMinutes()).padStart(2, '0');
      return `${y}-${mo}-${da}T${h}:${mi}`;
    };

    const overlay = document.createElement('div');
    overlay.className = 'edit-overlay';
    overlay.innerHTML = `
      <div class="edit-box">
        <h3>Edit Times</h3>
        <div class="edit-field">
          <label>Start Time</label>
          <input type="datetime-local" id="edit-start" value="${fmt(startDate)}">
        </div>
        <div class="edit-field">
          <label>End Time</label>
          <input type="datetime-local" id="edit-end" value="${fmt(endDate)}">
        </div>
        <div class="edit-actions">
          <button class="btn-edit-cancel">Cancel</button>
          <button class="btn-edit-save">Save</button>
        </div>
      </div>`;
    document.body.appendChild(overlay);

    overlay.querySelector('.btn-edit-cancel').addEventListener('click', () => overlay.remove());
    overlay.querySelector('.btn-edit-save').addEventListener('click', () => {
      const newStart = new Date(overlay.querySelector('#edit-start').value).getTime();
      const newEnd = new Date(overlay.querySelector('#edit-end').value).getTime();

      if (!newStart || !newEnd || newEnd <= newStart) {
        alert('End time must be after start time.');
        return;
      }

      state.startTime = newStart;
      state.durationDays = (newEnd - newStart) / (24 * 3600 * 1000);
      saveState();
      overlay.remove();
      tick();
      buildTimeline();
    });
  });
}

// ---------- NOTIFICATIONS ----------
function requestNotificationPermission() {
  if ('Notification' in window && Notification.permission === 'default') {
    Notification.requestPermission();
  }
}

function scheduleNotifications() {
  if (!('Notification' in window) || Notification.permission !== 'granted') return;
  if (!('serviceWorker' in navigator)) return;

  navigator.serviceWorker.ready.then(reg => {
    EVENTS.forEach(evt => {
      if (evt.hour === 0) return;
      const delay = (evt.hour * 3600 * 1000) - (Date.now() - state.startTime);
      if (delay <= 0) return;

      reg.active.postMessage({
        type: 'SCHEDULE_NOTIFICATION',
        title: `🔥 ${evt.title}`,
        body: `${evt.desc}\n\n💪 ${evt.quote}`,
        delay,
      });
    });

    // Periodic check-ins every 6 hours
    const totalH = state.durationDays * 24;
    for (let h = 6; h <= totalH; h += 6) {
      const hasNearby = EVENTS.some(e => Math.abs(e.hour - h) <= 2);
      if (hasNearby) continue;
      const delay = (h * 3600 * 1000) - (Date.now() - state.startTime);
      if (delay <= 0) continue;
      const msgs = [
        `You're ${h} hours in! Your body is transforming. Stay strong! 💪`,
        `${h} hours of fasting! Remember why you started.`,
        `Hour ${h} — Your willpower is incredible. Keep going!`,
        `${h}h in! Think about how amazing you'll feel at the finish!`,
        `Still going at ${h} hours! Most people can't do what you're doing. 🏆`,
      ];
      reg.active.postMessage({
        type: 'SCHEDULE_NOTIFICATION',
        title: '⏱ Fasting Check-in',
        body: msgs[h % msgs.length],
        delay,
      });
    }
  });
}

// ---------- SERVICE WORKER ----------
function registerSW() {
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('sw.js').catch(() => {});
  }
}

// ---------- INIT ----------
document.addEventListener('DOMContentLoaded', () => {
  registerSW();
  injectRingGradient();
  initSetup();
  initTabs();
  initFilters();
  initEndFast();
  initEditTimes();

  // Resume existing session
  if (loadState()) {
    const elapsed = (Date.now() - state.startTime) / 1000;
    const total = state.durationDays * 24 * 3600;
    if (elapsed < total) {
      showApp();
    } else {
      clearState();
    }
  }
});
