window.addEventListener('message', function (event) {
    const data = event.data;
    // console.log('[NUI] Message received:', data.action);

    if (data.action === 'open') {
        window.materialConfig = data.materialConfig; // Store for lookup
        openMenu(data.wagons);
    } else if (data.action === 'close') {
        closeMenu();
    } else if (data.action === 'openOptions') {
        // Used for Livery/Tint selection
        openOptions(data.title, data.options, data.callbackName, data.layout);
    } else if (data.action === 'openManagement') {
        openManagement(data.balance, data.grade);
    }
});

document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') {
        event.preventDefault(); // Prevent default console interaction
        closeMenu(true); // true = notify client
    }
});

function openMenu(wagons) {
    const container = document.getElementById('wagon-list');
    const app = document.getElementById('app');
    const wagonContainer = document.querySelector('.wagon-container');
    const managementMenu = document.getElementById('management-menu');

    if (!container || !app) return;

    // Reset UI state
    if (wagonContainer) wagonContainer.classList.remove('parking-mode');
    if (managementMenu) managementMenu.style.display = 'none';
    if (container) container.style.display = 'grid';
    document.getElementById('category-tabs').style.display = 'flex';
    document.getElementById('option-list').style.display = 'none';

    container.innerHTML = ''; // Clear existing

    if (!wagons || wagons.length === 0) return;

    try {
        // Extract Categories
        const categories = ['all'];
        wagons.forEach(w => {
            if (w.category && !categories.includes(w.category)) {
                categories.push(w.category);
            }
        });

        // Render Tabs
        const tabContainer = document.getElementById('category-tabs');
        if (tabContainer) {
            tabContainer.innerHTML = '';
            categories.forEach(cat => {
                const btn = document.createElement('button');
                btn.className = 'tab-btn';
                btn.innerText = cat.charAt(0).toUpperCase() + cat.slice(1);
                if (cat === 'all') btn.classList.add('active');

                btn.onclick = () => {
                    // Update active state
                    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
                    btn.classList.add('active');
                    // Filter list
                    renderWagons(wagons, cat);
                };
                tabContainer.appendChild(btn);
            });
        }

        // Render Initial List (All)
        renderWagons(wagons, 'all');

        app.style.display = 'flex';
    } catch (e) { }
}

function openManagement(balance, grade) {
    const app = document.getElementById('app');
    const wagonList = document.getElementById('wagon-list');
    const optionList = document.getElementById('option-list');
    const tabs = document.getElementById('category-tabs');
    const managementMenu = document.getElementById('management-menu');
    const balanceEl = document.getElementById('management-balance');
    const jobMgmtBtn = document.getElementById('btn-job-mgmt');

    if (!app || !managementMenu) return;

    // Force visibility FIRST to ensure menu opens
    app.style.display = 'flex';
    managementMenu.style.display = 'grid';

    // Hide standard shop elements
    if (wagonList) wagonList.style.display = 'none';
    if (optionList) optionList.style.display = 'none';
    if (tabs) tabs.style.display = 'none';

    // Toggle Boss Menu based on Grade
    if (jobMgmtBtn) {
        if (grade >= 3) {
            jobMgmtBtn.style.display = 'flex'; // or 'block' depending on flex needs, usually flex for cards
        } else {
            jobMgmtBtn.style.display = 'none';
        }
    }

    // Update balance
    if (balanceEl) {
        try {
            const numBalance = Number(balance);
            balanceEl.innerText = '$' + (isNaN(numBalance) ? '0.00' : numBalance.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 }));
        } catch (e) {
            console.error('[WagonMaker] Error formatting balance:', e);
            balanceEl.innerText = '$0.00';
        }
    }
}

function triggerManagement(action) {
    if (action === 'boss') {
        // Open Internal Employee Menu
        document.getElementById('management-menu').style.display = 'none';
        document.getElementById('employee-menu').style.display = 'grid'; // Grid like management
        loadEmployees();
    } else if (action === 'deposit' || action === 'withdraw') {
        // Call client directly for input dialogs
        fetch(`https://${GetParentResourceName()}/managementOption`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({ action: action })
        });
    }
}

function backToManagement() {
    // Return to main management menu
    document.getElementById('employee-menu').style.display = 'none';
    document.getElementById('management-menu').style.display = 'grid';
}

// ========================================
// Employee Management Logic
// ========================================

async function loadEmployees() {
    const listContainer = document.getElementById('employee-list-container');
    listContainer.innerHTML = '<div class="player-item">Loading employees...</div>';

    // Fetch from client
    const response = await fetch(`https://${GetParentResourceName()}/getEmployees`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    });

    if (response.ok) {
        const employees = await response.json();
        renderEmployees(employees);
    } else {
        listContainer.innerHTML = '<div class="player-item">Failed to load employees.</div>';
    }
}

function renderEmployees(employees) {
    const listContainer = document.getElementById('employee-list-container');
    listContainer.innerHTML = '';

    if (!employees || employees.length === 0) {
        listContainer.innerHTML = '<div class="player-item">No employees found.</div>';
        return;
    }

    employees.forEach(emp => {
        const item = document.createElement('div');
        item.className = 'employee-item';

        // Grade Labels
        const gradeLabels = ['Apprentice', 'Craftsman', 'Manager', 'Owner'];
        const gradeLabel = gradeLabels[emp.grade] || 'Unknown';

        item.innerHTML = `
            <div class="employee-info">
                <span class="employee-name">${emp.name}</span>
                <span class="employee-grade">${gradeLabel} (Grade ${emp.grade})</span>
            </div>
            <div class="employee-actions">
                ${emp.grade < 3 ? `<button class="promote" onclick="promoteEmployee('${emp.citizenid}', ${emp.grade})"><i class="fas fa-arrow-up"></i></button>` : ''}
                <button onclick="fireEmployee('${emp.citizenid}')"><i class="fas fa-user-times"></i></button>
            </div>
        `;
        listContainer.appendChild(item);
    });
}

async function promoteEmployee(citizenId, currentGrade) {
    const newGrade = currentGrade + 1;
    await fetch(`https://${GetParentResourceName()}/updateGrade`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ citizenId: citizenId, newGrade: newGrade })
    });
    // Refresh list
    setTimeout(loadEmployees, 500);
}

async function fireEmployee(citizenId) {
    await fetch(`https://${GetParentResourceName()}/firePlayer`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ citizenId: citizenId })
    });
    // Refresh list
    setTimeout(loadEmployees, 500);
}

// Hire Modal Logic
function openHireModal() {
    document.getElementById('hire-modal').style.display = 'flex';
    loadNearbyPlayers();
}

function closeHireModal() {
    document.getElementById('hire-modal').style.display = 'none';
}

async function loadNearbyPlayers() {
    const list = document.getElementById('nearby-players-list');
    list.innerHTML = '<div class="player-item">Searching...</div>';

    const response = await fetch(`https://${GetParentResourceName()}/getNearbyPlayers`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    });

    if (response.ok) {
        const players = await response.json();
        list.innerHTML = '';

        if (players.length === 0) {
            list.innerHTML = '<div class="player-item">No one nearby.</div>';
            return;
        }

        players.forEach(p => {
            const item = document.createElement('div');
            item.className = 'player-item';
            item.innerHTML = `<strong>${p.name}</strong> (ID: ${p.source})`;
            item.onclick = () => hirePlayer(p.source);
            list.appendChild(item);
        });
    }
}

async function hirePlayer(targetId) {
    await fetch(`https://${GetParentResourceName()}/hirePlayer`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ targetId: targetId })
    });
    closeHireModal();
    setTimeout(loadEmployees, 500);
}

function renderWagons(allWagons, category) {
    const container = document.getElementById('wagon-list');
    container.innerHTML = '';

    const filtered = category === 'all'
        ? allWagons
        : allWagons.filter(w => w.category === category);

    filtered.forEach(wagon => {
        const card = document.createElement('div');
        card.className = 'wagon-card';
        card.onclick = () => selectWagon(wagon.model);

        const icon = document.createElement('div');
        icon.className = 'wagon-icon';
        icon.innerHTML = '<i class="fas fa-horse-head"></i>';

        const name = document.createElement('div');
        name.className = 'wagon-name';
        name.innerText = wagon.label;

        const price = document.createElement('div');
        price.className = 'wagon-price';
        price.innerText = wagon.price > 0 ? '$' + wagon.price : 'Free Assembly';

        const desc = document.createElement('div');
        desc.className = 'wagon-desc';
        desc.innerText = wagon.description || 'A sturdy wagon.';

        card.appendChild(icon);
        card.appendChild(name);
        // Price removed - crafting uses materials only
        card.appendChild(desc);

        // Materials Logic
        if (wagon.materials && wagon.materials.length > 0 && window.materialConfig) {
            const materialsDiv = document.createElement('div');
            materialsDiv.className = 'wagon-materials';

            wagon.materials.forEach(mat => {
                const matInfo = window.materialConfig[mat.item];
                const label = matInfo ? matInfo.label : mat.item;

                const matSpan = document.createElement('span');
                matSpan.innerText = `${mat.amount}x ${label}`;
                materialsDiv.appendChild(matSpan);
            });

            card.appendChild(materialsDiv);
        }

        container.appendChild(card);
    });
}

function closeMenu(notifyClient = false) {
    document.getElementById('app').style.display = 'none';
    const managementMenu = document.getElementById('management-menu');
    if (managementMenu) managementMenu.style.display = 'none'; // Reset

    if (notifyClient) {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({})
        });
    }
}

function selectWagon(model) {
    // Play sound or effect if desired
    closeMenu(false); // Close UI immediately
    fetch(`https://${GetParentResourceName()}/selectWagon`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ model: model })
    });
}

// ====== Customization Options Menu ======

function openOptions(title, options, callbackName, layout) {
    const app = document.getElementById('app');
    const wagonList = document.getElementById('wagon-list');
    const optionList = document.getElementById('option-list');
    const tabs = document.getElementById('category-tabs');
    const container = document.querySelector('.wagon-container');

    if (!optionList || !app) return;

    // Toggle parking mode class based on callback name
    if (callbackName && callbackName.includes('parking')) {
        container.classList.add('parking-mode');
    } else {
        container.classList.remove('parking-mode');
    }

    // console.log('[NUI] openOptions called with layout:', layout);

    // Apply layout class if specified
    if (layout === 'list') {
        optionList.classList.add('single-col');
    } else {
        optionList.classList.remove('single-col');
    }

    // Hide main list, show option list
    if (wagonList) wagonList.style.display = 'none';
    if (tabs) tabs.style.display = 'none';
    optionList.style.display = 'grid';
    optionList.innerHTML = '';

    // Optional: Add a back button or title
    const titleDiv = document.createElement('div');
    titleDiv.className = 'option-title';
    titleDiv.innerText = title;
    optionList.appendChild(titleDiv);

    options.forEach(opt => {
        const card = document.createElement('div');
        card.className = 'wagon-card'; // Reuse same visual style
        card.onclick = () => selectOption(callbackName, opt.value);

        if (opt.icon) {
            const icon = document.createElement('div');
            icon.className = 'wagon-icon';
            // Support both shorthand ('box') and full class ('fas fa-box')
            const iconClass = opt.icon.startsWith('fa') ? opt.icon : `fas fa-${opt.icon}`;
            icon.innerHTML = `<i class="${iconClass}"></i>`;
            card.appendChild(icon);
        }

        const name = document.createElement('div');
        name.className = 'wagon-name';
        name.innerText = opt.label;

        card.appendChild(name);
        optionList.appendChild(card);
    });

    app.style.display = 'flex';
    // Note: Focus is already set by client
}

function closeOptions() {
    const wagonList = document.getElementById('wagon-list');
    const optionList = document.getElementById('option-list');
    const tabs = document.getElementById('category-tabs');
    const app = document.getElementById('app');

    if (optionList) {
        optionList.style.display = 'none';
        optionList.innerHTML = '';
    }
    if (wagonList) wagonList.style.display = 'grid';
    if (tabs) tabs.style.display = 'flex';
    if (app) app.style.display = 'none';
}

function selectOption(callbackName, value) {
    // Send selection back to client
    closeOptions();
    fetch(`https://${GetParentResourceName()}/${callbackName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ value: value })
    });
}
