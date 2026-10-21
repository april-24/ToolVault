import { initializeApp } from 'https://www.gstatic.com/firebasejs/12.19.0/firebase-app.js';
import { getAuth, signInAnonymously } from 'https://www.gstatic.com/firebasejs/12.19.0/firebase-auth.js';
import {
  collection, deleteField, doc, getDoc, getDocs, getFirestore, query, runTransaction,
  serverTimestamp, updateDoc, where,
} from 'https://www.gstatic.com/firebasejs/12.19.0/firebase-firestore.js';

const firebaseConfig = {
  apiKey: 'AIzaSyALDWmx0JWVenUhV-kOUYauhwnheQ6dPSo',
  appId: '1:395232088266:web:d5149f0744e2a754b9e433',
  messagingSenderId: '395232088266',
  projectId: 'toolvault-271d9',
  authDomain: 'toolvault-271d9.firebaseapp.com',
  storageBucket: 'toolvault-271d9.firebasestorage.app',
  measurementId: 'G-WTGC7TFH1Q',
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const $ = (id) => document.getElementById(id);
const screens = ['welcome-screen', 'entry-screen', 'result-screen'];
const lockerBaseByTool = {
  step_ladder: 1, cordless_drill: 3, wet_dry_vacuum: 6, carpet_cleaner: 8,
  pressure_washer: 9, steam_cleaner: 10, hand_truck: 11, furniture_kit: 13,
  laser_measure: 14, laser_level: 15, stud_finder: 16, workbench: 17,
  drain_auger: 18, dehumidifier: 19, window_kit: 20,
};

let mode = 'pickup';
let activeRental = null;
let cameraStream = null;
let cameraMode = null;
let barcodeDetector = null;
let scanFrame = 0;
let sensorFrame = 0;
let sensorDarkSince = 0;
let sensorStartedAt = 0;
let sensorAutoReturnStarted = false;
let welcomeResetTimer = null;
let busy = false;
let authReady;
let authError = null;

const safetyNotes = {
  step_ladder: 'Open fully, lock the braces, use on level ground, keep three points of contact, and never stand on the top step.',
  cordless_drill: 'Wear eye protection, secure the work, check for wires and pipes, and remove the battery before changing bits.',
  wet_dry_vacuum: 'Use the correct filter and mode. Never vacuum hot ash or flammable liquids. Unplug before emptying.',
  carpet_cleaner: 'Test a hidden patch first, use only the recommended solution, and rinse and empty the tanks after use.',
  pressure_washer: 'Start at low pressure and keep the spray away from people, pets, electrical items, and fragile surfaces.',
  steam_cleaner: 'Steam can burn. Keep the nozzle away from people and pets, then unplug and cool the unit before refilling.',
  hand_truck: 'Stay within the marked load limit, secure the load, move slowly, and keep hands and feet clear.',
  furniture_kit: 'Keep fingers clear and get another person to help with heavy furniture. Stop if the load becomes unstable.',
  laser_measure: 'Aim at the target surface. Never look into the laser or point it at another person.',
  laser_level: 'Use the stable mount and do not look into or aim the laser beam at anyone’s eyes.',
  stud_finder: 'Scan slowly in both directions. This detector cannot guarantee a wall is safe to drill.',
  workbench: 'Lock the legs and clamps, stay within the load limit, and never stand or sit on the bench.',
  drain_auger: 'Wear gloves and eye protection. Never use with chemical drain cleaner; do not force the cable.',
  dehumidifier: 'Keep upright on a dry, level floor with vents clear. Unplug before cleaning or moving it.',
  window_kit: 'Use from the ground only. Do not lean out of windows or climb on furniture or a balcony rail.',
};

function setConnection(message, state = '') {
  const node = $('connection-state');
  node.className = `connection ${state}`;
  node.lastChild.textContent = ` ${message}`;
}

function showScreen(id) {
  screens.forEach((screen) => $(screen).classList.toggle('hidden', screen !== id));
}

function lockerFor(data) {
  if (data.locker_id) return data.locker_id;
  const base = lockerBaseByTool[data.tool_id] ?? 1;
  const unit = Number(String(data.asset_id ?? '').replace(/\D/g, '')) || 1;
  return `LOCKER${String(base + unit - 1).padStart(2, '0')}`;
}

function friendlyLocker(value) {
  const digits = String(value).replace(/\D/g, '');
  return `LOCKER ${digits.padStart(2, '0')}`;
}

function setMode(nextMode) {
  mode = nextMode;
  activeRental = null;
  $('pin-input').value = '';
  $('entry-error').classList.add('hidden');
  $('entry-eyebrow').textContent = mode === 'pickup' ? 'RESERVATION PICKUP' : 'TOOL RETURN';
  $('entry-title').textContent = mode === 'pickup' ? 'VERIFY YOUR PICKUP PASS' : 'VERIFY YOUR RETURN PASS';
  $('entry-copy').textContent = mode === 'pickup'
    ? 'Scan the QR from the resident app or enter its six-digit PIN.'
    : 'Open the borrowed rental in My Rentals, then scan its fresh return QR or enter its return PIN.';
  $('field-label').textContent = mode === 'pickup' ? 'PICKUP PIN' : 'RETURN PIN';
  $('verify-pass').textContent = mode === 'pickup' ? 'VERIFY PASS & OPEN LOCKER' : 'VERIFY PASS & OPEN RETURN LOCKER';
  $('pin-input').placeholder = mode === 'pickup' ? 'Enter 6-digit PIN' : 'Enter return PIN';
  showScreen('entry-screen');
  $('pin-input').focus();
}

function showError(message) {
  const node = $('entry-error');
  node.textContent = message;
  node.classList.remove('hidden');
}

function scheduleWelcomeReset() {
  if (welcomeResetTimer) clearTimeout(welcomeResetTimer);
  welcomeResetTimer = setTimeout(() => {
    welcomeResetTimer = null;
    activeRental = null;
    $('pin-input').value = '';
    showScreen('welcome-screen');
  }, 10000);
}

function showLockerResult(data, action) {
  if (welcomeResetTimer) clearTimeout(welcomeResetTimer);
  welcomeResetTimer = null;
  activeRental = data;
  const locker = friendlyLocker(lockerFor(data));
  $('result-tool').textContent = data.tool_name ?? data.tool_id ?? 'Reserved tool';
  $('result-eyebrow').textContent = action === 'pickup' ? 'PICKUP CONFIRMED' : 'RETURN PASS VERIFIED';
  $('result-title').textContent = action === 'pickup' ? `${locker} OPENED` : `${locker} OPENED FOR RETURN`;
  $('result-icon').textContent = action === 'pickup' ? '↗' : '↩';
  $('locker-instruction').textContent = action === 'pickup'
    ? `Please take the ${data.tool_name} from ${locker}. Take care while using it. When ready to return, open this rental in My Rentals to generate a fresh return PIN and QR.`
    : `Please put the ${data.tool_name} back into ${locker}. After placing it inside, close the locker and use the camera simulation to confirm the return.`;
  $('result-safety').textContent = action === 'pickup'
    ? `SAFETY REMINDER · ${safetyNotes[data.tool_id] ?? 'Read the tool’s safety guide in the resident app before use.'}`
    : `RETURN CHECK · The camera preview is a simulation of the occupancy sensor inside ${locker}.`;
  const actions = $('result-actions');
  actions.replaceChildren();
  if (action === 'return') {
    const sensorButton = document.createElement('button');
    sensorButton.className = 'button primary';
    sensorButton.textContent = 'OPEN OCCUPANCY SENSOR CAMERA';
    sensorButton.addEventListener('click', () => openCamera('sensor'));
    actions.append(sensorButton);
  }
  showScreen('result-screen');
  if (action === 'pickup') scheduleWelcomeReset();
}

async function findRental(credential) {
  const isPin = /^\d{6}$/.test(credential);
  const field = mode === 'pickup'
    ? (isPin ? 'pin' : 'pickup_qr')
    : (isPin ? 'return_pin' : 'return_qr');
  const matches = await getDocs(query(collection(db, 'reservations'), where(field, '==', credential)));
  const matchingDocs = matches.docs.map((item) => ({ ref: item.ref, id: item.id, ...item.data() }));
  const match = matchingDocs.find((item) => {
    if (mode === 'pickup') return item.status === 'reserved';
    const expiry = item.return_expires_at?.toDate?.();
    return ['return_requested', 'return_scanning'].includes(item.status) && expiry && expiry.getTime() > Date.now();
  });
  if (!match) {
    if (mode === 'pickup' && matchingDocs.some((item) => ['borrowed', 'return_scanning', 'return_requested'].includes(item.status))) {
      throw new Error('This tool is already borrowed. Open it from My Rentals to generate a fresh return PIN and QR.');
    }
    const expiredPass = mode === 'return' && matchingDocs.find((item) => ['return_requested', 'return_scanning'].includes(item.status));
    if (expiredPass) {
      await updateDoc(expiredPass.ref, {
        status: 'borrowed',
        return_pin: deleteField(),
        return_qr: deleteField(),
        return_expires_at: deleteField(),
      });
      throw new Error('The two-minute return pass expired. Reopen the rental in My Rentals to generate a new one.');
    }
    throw new Error(mode === 'pickup'
      ? 'No active reservation matched this PIN or QR. Reservations must be collected within 15 minutes.'
      : 'No active return pass matched this PIN or QR. Open the rental in My Rentals to generate a fresh return pass.');
  }
  return match;
}

async function verifyPass(value = $('pin-input').value) {
  if (busy) return;
  const credential = value.trim();
  if (!credential) {
    showError('Enter the six-digit PIN or scan the rental QR.');
    return;
  }
  if (/^\d+$/.test(credential) && !/^\d{6}$/.test(credential)) {
    showError('The PIN must contain six digits.');
    return;
  }
  busy = true;
  $('verify-pass').disabled = true;
  $('verify-pass').textContent = 'VERIFYING…';
  $('entry-error').classList.add('hidden');
  try {
    await authReady;
    if (authError) throw new Error(`Firebase sign-in failed: ${authError.message}`);
    const rental = await findRental(credential);
    const ref = doc(db, 'reservations', rental.id);
    let updated;
    if (mode === 'pickup') {
      const expiry = rental.pickup_expires_at?.toDate?.();
      if (!expiry || expiry.getTime() < Date.now()) throw new Error('This pickup pass expired after 15 minutes. Please make a new reservation.');
      await runTransaction(db, async (transaction) => {
        const latest = await transaction.get(ref);
        if (!latest.exists() || latest.data().status !== 'reserved') throw new Error('This reservation has already been collected or expired.');
        const deadline = latest.data().pickup_expires_at?.toDate?.();
        if (!deadline || deadline.getTime() < Date.now()) throw new Error('This pickup pass expired after 15 minutes. Please make a new reservation.');
        transaction.update(ref, { status: 'borrowed', picked_up_at: serverTimestamp() });
      });
      updated = { ...rental, status: 'borrowed' };
    } else {
      await runTransaction(db, async (transaction) => {
        const latest = await transaction.get(ref);
        const current = latest.data();
        const expiry = current?.return_expires_at?.toDate?.();
        if (!latest.exists() || !current || !['return_requested', 'return_scanning'].includes(current.status) || !expiry || expiry.getTime() <= Date.now()) throw new Error('This two-minute return pass expired. Generate a new pass from My Rentals.');
        if (current.status === 'return_requested') transaction.update(ref, { status: 'return_scanning' });
        updated = { ...rental, ...current, status: 'return_scanning' };
      });
    }
    showLockerResult(updated, mode);
  } catch (error) {
    showError(error.message || 'Could not verify that pass. Please try again.');
  } finally {
    busy = false;
    $('verify-pass').disabled = false;
    $('verify-pass').textContent = mode === 'pickup' ? 'VERIFY PASS & OPEN LOCKER' : 'VERIFY PASS & OPEN RETURN LOCKER';
  }
}

function rentalFee(data) {
  const start = data.picked_up_at?.toDate?.();
  const elapsed = start ? Math.max(0, Math.floor((Date.now() - start.getTime()) / 1000)) : 0;
  const chargeHours = Math.max(1, Math.ceil(elapsed / 3600));
  return { elapsed, fee: Number((chargeHours * Number(data.hourly_rate || 0)).toFixed(2)) };
}

async function confirmSimulatedReturn() {
  if (!activeRental || busy) return;
  busy = true;
  const rentalRef = doc(db, 'reservations', activeRental.id);
  try {
    const toolRef = doc(db, 'tools', activeRental.tool_id);
    const charge = rentalFee(activeRental);
    await runTransaction(db, async (transaction) => {
      const rentalSnapshot = await transaction.get(rentalRef);
      const toolSnapshot = await transaction.get(toolRef);
      const rentalData = rentalSnapshot.data();
      const expiry = rentalData?.return_expires_at?.toDate?.();
      if (!rentalSnapshot.exists() || rentalData?.status !== 'return_scanning') throw new Error('Return pass is no longer active. Verify the return again.');
      if (!expiry || expiry.getTime() <= Date.now()) {
        throw new Error('The two-minute return pass expired. Generate a new pass from My Rentals.');
      }
      if (!toolSnapshot.exists()) throw new Error('Tool inventory record is missing. Contact township support.');
      const toolData = toolSnapshot.data();
      const available = [...(toolData.available_assets || [])];
      const asset = rentalSnapshot.data().asset_id;
      if (asset && !available.includes(asset)) available.push(asset);
      transaction.update(toolRef, { available_assets: available, updated_at: serverTimestamp() });
      transaction.update(rentalRef, {
        status: 'returned', returned_at: serverTimestamp(),
        elapsed_seconds: charge.elapsed, rental_fee: charge.fee,
        return_pin: deleteField(), return_qr: deleteField(),
        return_expires_at: deleteField(),
      });
    });
    closeCamera();
    $('result-eyebrow').textContent = 'RETURN COMPLETE';
    $('result-title').textContent = 'TOOL RETURNED';
    $('result-icon').textContent = '✓';
    $('locker-instruction').textContent = `${activeRental.tool_name} has been returned to ${friendlyLocker(lockerFor(activeRental))}.`;
    $('result-safety').textContent = `RENTAL TIME · ${Math.floor(charge.elapsed / 3600).toString().padStart(2, '0')}:${Math.floor((charge.elapsed % 3600) / 60).toString().padStart(2, '0')}:${(charge.elapsed % 60).toString().padStart(2, '0')}   ·   RENTAL FEE · RM ${charge.fee.toFixed(2)}`;
    $('result-actions').replaceChildren();
    activeRental = null;
    showScreen('result-screen');
    scheduleWelcomeReset();
  } catch (error) {
    if (String(error.message).includes('two-minute return pass expired')) {
      try {
        await updateDoc(rentalRef, {
          status: 'borrowed',
          return_pin: deleteField(),
          return_qr: deleteField(),
          return_expires_at: deleteField(),
        });
      } catch (_) { /* The resident app will also expire the pass on its next refresh. */ }
    }
    $('camera-message').textContent = error.message || 'Return could not be completed.';
    $('camera-message').classList.add('error');
  } finally {
    busy = false;
  }
}

function startOccupancyDetection(video) {
  const canvas = document.createElement('canvas');
  canvas.width = 32;
  canvas.height = 24;
  const context = canvas.getContext('2d', { willReadFrequently: true });
  sensorStartedAt = performance.now();
  sensorDarkSince = 0;
  sensorAutoReturnStarted = false;

  const sample = () => {
    if (!cameraStream || cameraMode !== 'sensor' || sensorAutoReturnStarted) return;
    if (video.readyState >= HTMLMediaElement.HAVE_CURRENT_DATA && video.videoWidth > 0) {
      context.drawImage(video, 0, 0, canvas.width, canvas.height);
      const pixels = context.getImageData(0, 0, canvas.width, canvas.height).data;
      let brightness = 0;
      for (let i = 0; i < pixels.length; i += 4) {
        brightness += (0.2126 * pixels[i]) + (0.7152 * pixels[i + 1]) + (0.0722 * pixels[i + 2]);
      }
      brightness /= pixels.length / 4;
      const now = performance.now();
      // Ignore camera startup frames, then require a sustained dark image so a
      // single black/underexposed frame cannot complete a return by mistake.
      if (now - sensorStartedAt >= 1800 && brightness <= 24) {
        if (!sensorDarkSince) sensorDarkSince = now;
        const darkFor = now - sensorDarkSince;
        $('camera-message').classList.remove('error');
        $('camera-message').textContent = darkFor >= 900
          ? 'Dark sensor reading detected. Completing the return…'
          : 'Dark frame detected. Keep the camera covered to confirm return…';
        if (darkFor >= 900) {
          sensorAutoReturnStarted = true;
          void confirmSimulatedReturn();
          return;
        }
      } else {
        sensorDarkSince = 0;
        $('camera-message').classList.remove('error');
        $('camera-message').textContent = `Sensor active · image brightness ${Math.round(brightness)}/255. Cover the camera until the image stays dark to complete the return.`;
      }
    }
    sensorFrame = requestAnimationFrame(sample);
  };
  sensorFrame = requestAnimationFrame(sample);
}

async function openCamera(kind) {
  cameraMode = kind;
  $('camera-modal').classList.remove('hidden');
  $('camera-title').textContent = kind === 'sensor' ? 'RETURN SENSOR CAMERA' : 'SCAN YOUR RENTAL QR';
  $('camera-eyebrow').textContent = kind === 'sensor' ? 'LOCKER OCCUPANCY SIMULATION' : 'RESERVATION PASS';
  $('scan-frame').classList.toggle('hidden', kind !== 'scan');
  $('sensor-caption').classList.toggle('hidden', kind !== 'sensor');
  $('camera-message').classList.remove('error');
  $('camera-message').textContent = kind === 'sensor' ? 'Starting a live camera preview…' : 'Point the camera at the QR pass in your resident app.';
  $('camera-placeholder').classList.remove('hidden');
  $('camera-placeholder').querySelector('b').textContent = 'TURNING ON CAMERA…';
  const actions = $('camera-actions');
  actions.replaceChildren();
  try {
    await stopCameraStream();
    if (!navigator.mediaDevices?.getUserMedia) throw new Error('Camera access needs a secure page (HTTPS or localhost) and a supported browser.');
    cameraStream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: { ideal: 'environment' } },
      audio: false,
    });
    const video = $('camera-video');
    video.srcObject = cameraStream;
    await video.play();
    $('camera-placeholder').classList.add('hidden');
    if (kind === 'sensor') {
      $('camera-message').textContent = 'Camera is live. Cover the camera until the image stays dark to simulate the tool occupying the locker.';
      startOccupancyDetection(video);
    } else {
      startQrDetection(video);
    }
  } catch (error) {
    $('camera-placeholder').querySelector('b').textContent = 'CAMERA UNAVAILABLE';
    $('camera-message').textContent = `${error.message || 'Camera permission was denied.'} You can still enter a six-digit PIN on the previous screen.`;
    $('camera-message').classList.add('error');
  }
}

async function startQrDetection(video) {
  try {
    if ('BarcodeDetector' in window) {
      try {
        const formats = await BarcodeDetector.getSupportedFormats();
        if (formats.includes('qr_code')) barcodeDetector = new BarcodeDetector({ formats: ['qr_code'] });
      } catch (_) { /* Use the jsQR fallback when the native decoder is unavailable. */ }
    }
    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d', { willReadFrequently: true });
    let lastScanAt = 0;
    if (!barcodeDetector && typeof window.jsQR !== 'function') {
      $('camera-message').textContent = 'Camera is live, but the QR decoder did not load. Check your internet connection and reload this page.';
      return;
    }
    $('camera-message').textContent = 'Center the rental QR inside the frame and hold it steady.';
    const scan = async () => {
      if (!cameraStream || cameraMode !== 'scan') return;
      try {
        let value = '';
        if (barcodeDetector) {
          const codes = await barcodeDetector.detect(video);
          value = codes[0]?.rawValue ?? '';
        } else if (video.readyState >= HTMLMediaElement.HAVE_CURRENT_DATA && performance.now() - lastScanAt > 140) {
          lastScanAt = performance.now();
          canvas.width = video.videoWidth;
          canvas.height = video.videoHeight;
          context.drawImage(video, 0, 0, canvas.width, canvas.height);
          const frame = context.getImageData(0, 0, canvas.width, canvas.height);
          value = window.jsQR(frame.data, frame.width, frame.height, { inversionAttempts: 'attemptBoth' })?.data ?? '';
        }
        if (value) {
          $('pin-input').value = value;
          closeCamera();
          await verifyPass(value);
          return;
        }
      } catch (_) {
        barcodeDetector = null;
        $('camera-message').textContent = 'Switching to the camera QR fallback. Keep the code centered and steady.';
      }
      scanFrame = requestAnimationFrame(scan);
    };
    scanFrame = requestAnimationFrame(scan);
  } catch (error) {
    $('camera-message').textContent = `${error.message} Close this panel and enter the PIN instead.`;
  }
}

async function stopCameraStream() {
  if (scanFrame) cancelAnimationFrame(scanFrame);
  if (sensorFrame) cancelAnimationFrame(sensorFrame);
  scanFrame = 0;
  sensorFrame = 0;
  sensorDarkSince = 0;
  sensorAutoReturnStarted = false;
  if (cameraStream) cameraStream.getTracks().forEach((track) => track.stop());
  cameraStream = null;
  $('camera-video').srcObject = null;
}

function closeCamera() {
  $('camera-modal').classList.add('hidden');
  $('scan-frame').classList.add('hidden');
  cameraMode = null;
  void stopCameraStream();
}

$('start-pickup').addEventListener('click', () => setMode('pickup'));
$('start-return').addEventListener('click', () => setMode('return'));
$('back-home').addEventListener('click', () => showScreen('welcome-screen'));
$('finish-screen').addEventListener('click', () => {
  if (welcomeResetTimer) clearTimeout(welcomeResetTimer);
  welcomeResetTimer = null;
  activeRental = null;
  $('pin-input').value = '';
  showScreen('welcome-screen');
});
$('verify-pass').addEventListener('click', () => verifyPass());
$('pin-input').addEventListener('keydown', (event) => { if (event.key === 'Enter') verifyPass(); });
$('scan-qr').addEventListener('click', () => openCamera('scan'));
$('close-camera').addEventListener('click', closeCamera);
$('camera-modal').addEventListener('click', (event) => { if (event.target === $('camera-modal')) closeCamera(); });
window.addEventListener('pagehide', () => {
  if (welcomeResetTimer) clearTimeout(welcomeResetTimer);
  void stopCameraStream();
});

authReady = signInAnonymously(auth)
  .then(() => setConnection('Firebase connected', 'online'))
  .catch((error) => {
    authError = error;
    setConnection('Firebase unavailable', 'offline');
    const note = document.querySelector('.welcome .quiet');
    note.textContent = `Firebase sign-in failed: ${error.message}. Enable Anonymous sign-in and check the project configuration.`;
    note.style.color = '#9e1b32';
  });
