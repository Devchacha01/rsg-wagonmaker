# 🐴 RSG Wagon Maker
**Advanced Wagon Crafting, Parking, and Employee Management System for RedM (RSGCore)**

`rsg-wagonmaker` is a feature-rich resource that enables players to own and manage their own Wagon Making business. It includes a complete crafting system, a persistent parking system with "Ghost Wagon" protection, and a full employee management system (Hire/Fire/Promote) integrated directly into the UI.

---

## ✨ Features

### 🛠️ Crafting System
- **Immersive UI**: Vintage-styled crafting menu with recipe lists and dynamic material requirements.
- **Visuals**: Crafting preview shows the wagon spinning before you build it.
- **Animations**: Realistic hammering animations (`WORLD_HUMAN_WAGON_HUB_MEND`) synchronized with progress bars.
- **Customization**: Wagons can have specialized tints, liveries, and extras applied automatically upon spawning.

### 🅿️ Advanced Parking System
- **Persistent Storage**: Wagons are saved to the database (`wagonmaker_wagons`) and persist across server restarts.
- **Ghost Wagon Protection**: The server automatically detects if a wagon entity despawns (due to OneSync issues or crashes) and "releases" it so the player can spawn it again without admin intervention.
- **Stash Integration**: Every wagon has a unique stash (`rsg-inventory`) accessible via Third Eye target on the wagon.

### 💼 Employee Management (Boss Menu)
- **In-Game Hiring**: Bosses can hire nearby players directly through the "Job Management" UI.
- **Roster Management**: View all employees, their grades, and their stats.
- **Promote/Fire**: Manage your workforce with simple UI buttons.
- **Strict Job Locations**: Supports location-based jobs (e.g., a "Blackwater Wagon Maker" cannot access the "Valentine" management menu).

---

## 📦 Installation

1.  **Dependencies**: Ensure you have the following resources installed and started:
    -   `rsg-core`
    -   `ox_lib`
    -   `ox_target` (Required for interaction)
    -   `ox_inventory` (Recommended for stashes/materials) OR `rsg-inventory`

2.  **Database Setup**:
    -   Import the provided SQL file `sql/wagonmaker.sql` into your database.
    -   **IMPORTANT**: Ensure the `wagon_maker_employees` table is created for the employee system to work.

    ```sql
    CREATE TABLE IF NOT EXISTS `wagon_maker_employees` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `job_name` varchar(50) NOT NULL,
      `citizenid` varchar(50) NOT NULL,
      `player_name` varchar(100) DEFAULT NULL,
      `grade` int(11) DEFAULT 0,
      `hired_date` timestamp NOT NULL DEFAULT current_timestamp(),
      PRIMARY KEY (`id`),
      UNIQUE KEY `unique_employee` (`job_name`, `citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ```

3.  **Add to Server Config**:
    -   Add `ensure rsg-wagonmaker` to your `server.cfg`.

4.  **Restart Server**: Start the server to load the resource.

---

## ⚙️ Configuration Guide (`config.lua`)

### 1. Adding/Editing Wagons
You can add new wagons or modify existing recipes in `Config.Wagons`.

```lua
cart01 = {
    label = "Light Peasant Cart",       -- Display Name
    description = "A simple cart...",   -- UI Description
    category = "carts",                 -- Category filter
    craftTime = 30000,                  -- Time in ms (30s)
    materials = {                       -- Required items
        { item = "wood_log", amount = 8 },
        { item = "iron_parts", amount = 4 },
    },
    price = 25,                         -- Production cost (optional)
    model = "cart01",                   -- Spawn Model Name
    maxWeight = 50000,                  -- Stash Weight (grams)
    slots = 15,                         -- Stash Slots
}
```

### 2. Job & Location Setup
You can control whether players need a specific job for each town's wagon workshop.

-   **`Config.JobMode = 'location'`**: (Recommended) Enforces strict location jobs. A player with `wagon_blackwater` job can ONLY operate in Blackwater.
-   **`Config.ParkingNPCs`**: Defines where players spawn/store wagons.
-   **`Config.StaticZones`**: Defines where the Crafting Circle (Third Eye) interaction is located.

**Example - Adding a New Location:**
1.  Go to the location in-game.
2.  Use `/wm_getcoords` (Admin only) to get accurate coordinates.
3.  Add a new entry to `Config.ParkingNPCs` (for the stable master) and `Config.StaticZones` (for the crafting circle).
4.  **Important**: Ensure `requiredJob` matches the job grade/name you want to restrict it to.

### 3. Tuning Performance
-   **`Config.UseOxTarget = true`**: Highly recommended to keep `true` for performance. Disabling it reverts to distance-based loop checks which are heavier.
-   **Zone Caching**: The server automatically caches zones. No config needed, works out of the box for 100+ players.

---

## 🎮 Player Guide

### How to Craft
1.  Go to the **Wagon Workshop** (Green Circle / Hammer Icon).
2.  **Alt-Click (Third Eye)** the zone and select **"Craft Wagon"**.
3.  Select a wagon from the list. You must have the required **Materials** in your inventory.
4.  Click **Craft**. Your character will start hammering.
5.  Once finished, the wagon is added to your "Garage/Stable".

### How to Spawn/Store
1.  Go to the **Wagon Yard** (NPC at the hitching post nearby).
2.  **Alt-Click** the NPC and select **"Access Wagon Yard"**.
3.  Select your wagon to **Spawn** it.
4.  To **Store**, bring the wagon close to the NPC, Alt-Click the NPC (or the wagon itself), and select **"Store Wagon"**.

### Employee Management (Boss Only)
1.  Open the **Crafting Menu**.
2.  Click **"Job Management"** button at the top.
3.  **Hire**: Click "Hire New", select a nearby player.
4.  **Fire/Promote**: Use the icons next to employee names.

---

## 🛠️ Developer Exports

**Server Exports:**
-   `exports['rsg-wagonmaker']:GetPlayerWagonCount(source)`
-   `exports['rsg-wagonmaker']:GetPlayerWagons(source)`
-   `exports['rsg-wagonmaker']:GetWagonById(wagonId)`
-   `exports['rsg-wagonmaker']:IsWagonSpawned(wagonId)`

**Common Issues:**
-   **"I can't see the Craft option!"**: Check your job. If you are `wagon_rhodes`, you cannot craft in Valentine.
-   **"My wagon disappeared!"**: The server auto-detects this. Go to the stable NPC, and it should let you spawn it again immediately.


