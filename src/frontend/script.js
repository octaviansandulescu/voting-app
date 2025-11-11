/**
 * 🎨 Frontend Logic - JavaScript
 * 
 * Ce face:
 * 1. Auto-detect API endpoint
 * 2. Vote handling
 * 3. Real-time results polling
 * 4. UI updates
 */

// ============================================================================
// 1. AUTO-DETECT API ENDPOINT (DevOPS: Environment Detection)
// ============================================================================

const API_URL = detectAPIEndpoint();

function detectAPIEndpoint() {
    const hostname = window.location.hostname;
    const protocol = window.location.protocol;
    
    if (hostname === 'localhost' || hostname === '127.0.0.1') {
        // Local development - backend on separate port
        return 'http://localhost:8000';
    } else {
        // Production/Kubernetes: Use nginx proxy at /api
        return `${protocol}//${hostname}/api`;
    }
}

console.log(`[APP] API Endpoint: ${API_URL}`);

// ============================================================================
// 2. VOTING FUNCTION
// ============================================================================

async function vote(choice) {
    console.log(`[VOTE] Casting vote for: ${choice}`);
    
    try {
        // Show loading state
        showMessage(`Voting for ${choice}...`, 'info');
        
        // Send vote to backend
        const response = await fetch(`${API_URL}/vote`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ vote: choice })
        });
        
        if (!response.ok) {
            throw new Error(`Vote failed: ${response.status}`);
        }
        
        // Success
        showMessage(`✅ Vote recorded for ${choice}!`, 'success');
        console.log('[VOTE] Success');
        
        // Refresh results immediately
        await updateResults();
        
    } catch (error) {
        console.error('[VOTE] Error:', error);
        showMessage(`❌ Error: ${error.message}`, 'error');
    }
}

// ============================================================================
// 3. FETCH RESULTS
// ============================================================================

async function updateResults() {
    try {
        console.log('[RESULTS] Fetching...');
        
        const response = await fetch(`${API_URL}/results`);
        
        if (!response.ok) {
            throw new Error(`Failed to fetch results: ${response.status}`);
        }
        
        const data = await response.json();
        console.log('[RESULTS] Data:', data);
        
        // Update UI
        updateUI(data);
        
        // Update timestamp
        const now = new Date();
        document.getElementById('last-update').textContent = now.toLocaleTimeString();
        
    } catch (error) {
        console.error('[RESULTS] Error:', error);
        showMessage(`⚠️ Cannot connect to API: ${error.message}`, 'warning');
    }
}

// ============================================================================
// 4. UPDATE UI
// ============================================================================

function updateUI(data) {
    const dogsCount = data.dogs || 0;
    const catsCount = data.cats || 0;
    const total = dogsCount + catsCount || 1;
    
    // Calculate percentages
    const dogsPercent = (dogsCount / total * 100).toFixed(1);
    const catsPercent = (catsCount / total * 100).toFixed(1);
    
    // Update counts
    document.getElementById('dogs-count').textContent = dogsCount;
    document.getElementById('cats-count').textContent = catsCount;
    document.getElementById('total-votes').textContent = total;
    
    // Update percentages
    document.getElementById('dogs-percent').textContent = dogsPercent + '%';
    document.getElementById('cats-percent').textContent = catsPercent + '%';
    
    // Update progress bars
    document.getElementById('dogs-bar').style.width = dogsPercent + '%';
    document.getElementById('cats-bar').style.width = catsPercent + '%';
}

// ============================================================================
// 5. MESSAGES
// ============================================================================

function showMessage(text, type = 'info') {
    const messageEl = document.getElementById('status-message');
    const errorEl = document.getElementById('error-message');
    
    if (type === 'error') {
        errorEl.textContent = text;
        errorEl.style.display = 'block';
        messageEl.style.display = 'none';
    } else if (type === 'warning') {
        messageEl.textContent = text;
        messageEl.className = 'status-message warning';
        messageEl.style.display = 'block';
        errorEl.style.display = 'none';
    } else {
        messageEl.textContent = text;
        messageEl.className = 'status-message ' + type;
        messageEl.style.display = 'block';
        errorEl.style.display = 'none';
    }
}

// ============================================================================
// 6. INITIALIZATION
// ============================================================================

document.addEventListener('DOMContentLoaded', async () => {
    console.log('[APP] Initializing...');
    
    // Load initial results
    await updateResults();
    
    // Refresh results every 1 second (Real-time)
    setInterval(updateResults, 1000);
    
    console.log('[APP] Ready! Polling results every 1 second');
});

// ============================================================================
// 7. ERROR HANDLING
// ============================================================================

window.addEventListener('error', (event) => {
    console.error('[APP] Unhandled error:', event.error);
    showMessage(`❌ Unexpected error: ${event.error.message}`, 'error');
});
