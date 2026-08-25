import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Rectangle {
    id: pvzPage
    objectName: "pvz"
    property string appId: "pvz"
    color: "#1E293B"
    signal exitRequested()
    signal backRequested()

    // --- Game Core States ---
    property int sun: 150
    property int score: 0
    property int level: 1
    property int wave: 1
    property int maxWaves: 3
    property double waveProgress: 0.0
    property bool gameRunning: false
    property bool gamePaused: false
    property bool gameWon: false
    property bool gameOver: false
    property double gameSpeed: 1.0

    // Selected plant card index (-1: none, 0-7: plants, 99: shovel)
    property int selectedPlantIdx: -1
    property bool shovelMode: false

    // Save notification
    property string toastText: ""
    property bool toastVisible: false

    // Grid Dimensions: 5 Rows x 9 Columns
    readonly property int gridRows: 5
    readonly property int gridCols: 9
    readonly property int cellWidth: 92
    readonly property int cellHeight: 96

    // Battlefield State Models
    // gridPlants: Array of { row, col, type, hp, maxHp, timer, state, digestTimer }
    property var gridPlants: []
    // zombies: Array of { id, row, x, type, hp, maxHp, speed, isEating, isFrozen, freezeTimer, isRaged, isCharred }
    property var zombiesList: []
    // projectiles: Array of { id, row, x, y, type, damage, speed, active }
    property var projectilesList: []
    // suns: Array of { id, x, y, targetY, value, isFalling, opacity }
    property var sunsList: []
    // lawnMowers: Array of 5 booleans (row 0 to 4)
    property var lawnMowers: [true, true, true, true, true]
    // mowerPositions: Array of x coordinates for running mowers (-1: idle on left)
    property var mowerPositions: [-1, -1, -1, -1, -1]

    // Plant Cards Definition
    readonly property var plantCards: [
        { id: "sunflower", name: "向日葵", cost: 50, cd: 7.5, hp: 300, icon: "🌻", desc: "生产阳光 (+25)", color: "#F59E0B" },
        { id: "peashooter", name: "豌豆射手", cost: 100, cd: 7.5, hp: 300, icon: "🟢", desc: "发射常规豌豆", color: "#10B981" },
        { id: "snowpea", name: "寒冰射手", cost: 175, cd: 7.5, hp: 300, icon: "❄️", desc: "发射减速冰豆", color: "#06B6D4" },
        { id: "wallnut", name: "坚果墙", cost: 50, cd: 20.0, hp: 4000, icon: "🌰", desc: "高耐久阻挡僵尸", color: "#D97706" },
        { id: "cherrybomb", name: "樱桃炸弹", cost: 150, cd: 25.0, hp: 300, icon: "💣", desc: "3x3 范围毁灭爆炸", color: "#EF4444" },
        { id: "potatomine", name: "土豆地雷", cost: 25, cd: 20.0, hp: 300, icon: "🥔", desc: "就绪后触碰即爆", color: "#84CC16" },
        { id: "repeater", name: "双发射手", cost: 200, cd: 7.5, hp: 300, icon: "🌿", desc: "一次发射双发豌豆", color: "#059669" },
        { id: "chomper", name: "大嘴花", cost: 150, cd: 10.0, hp: 300, icon: "🟣", desc: "吞噬整只近身僵尸", color: "#8B5CF6" }
    ]

    // Cooldown tracking for cards (0.0 to 1.0)
    property var cardCooldowns: [0, 0, 0, 0, 0, 0, 0, 0]

    // --- Save & Load Engine (退出自动保存与恢复) ---
    function saveGame() {
        if (!systemBackend) return
        var saveData = {
            hasSave: gameRunning && !gameOver && !gameWon,
            sun: sun,
            score: score,
            level: level,
            wave: wave,
            maxWaves: maxWaves,
            waveProgress: waveProgress,
            gridPlants: gridPlants,
            zombiesList: zombiesList,
            lawnMowers: lawnMowers,
            mowerPositions: mowerPositions,
            timestamp: Date.now()
        }
        var jsonStr = JSON.stringify(saveData)
        systemBackend.saveAppData("meow_pvz_saved_battle", jsonStr)
        showToast("💾 游戏进度已自动保存")
        console.log("[PvZ] Game state saved successfully.")
    }

    function loadSavedGame() {
        if (!systemBackend) return false
        var jsonStr = systemBackend.loadAppData("meow_pvz_saved_battle", "")
        if (!jsonStr || jsonStr.length < 10) return false
        try {
            var data = JSON.parse(jsonStr)
            if (data && data.hasSave) {
                sun = data.sun || 150
                score = data.score || 0
                level = data.level || 1
                wave = data.wave || 1
                maxWaves = data.maxWaves || 3
                waveProgress = data.waveProgress || 0
                gridPlants = data.gridPlants || []
                zombiesList = data.zombiesList || []
                lawnMowers = data.lawnMowers || [true, true, true, true, true]
                mowerPositions = data.mowerPositions || [-1, -1, -1, -1, -1]
                gameRunning = true
                gameOver = false
                gameWon = false
                gameLoopTimer.restart()
                sunDropTimer.restart()
                zombieWaveTimer.restart()
                showToast("✨ 已恢复上次战斗进度")
                return true
            }
        } catch (e) {
            console.log("[PvZ] Load save error:", e)
        }
        return false
    }

    function clearSave() {
        if (systemBackend) {
            systemBackend.saveAppData("meow_pvz_saved_battle", "")
        }
    }

    function showToast(msg) {
        toastText = msg
        toastVisible = true
        toastTimer.restart()
    }

    Timer {
        id: toastTimer
        interval: 2200
        onTriggered: pvzPage.toastVisible = false
    }

    // --- Game Lifecycle ---
    function startNewGame(lvl) {
        clearSave()
        level = lvl || 1
        sun = 150
        score = 0
        wave = 1
        maxWaves = 2 + level
        waveProgress = 0
        gridPlants = []
        zombiesList = []
        projectilesList = []
        sunsList = []
        lawnMowers = [true, true, true, true, true]
        mowerPositions = [-1, -1, -1, -1, -1]
        cardCooldowns = [0, 0, 0, 0, 0, 0, 0, 0]
        selectedPlantIdx = -1
        shovelMode = false
        gameOver = false
        gameWon = false
        gamePaused = false
        gameRunning = true

        gameLoopTimer.restart()
        sunDropTimer.restart()
        zombieWaveTimer.restart()
        showToast("🌻 关卡 " + level + " 开始！守卫草坪！")
    }

    function exitGame() {
        saveGame()
        gameRunning = false
        gameLoopTimer.stop()
        sunDropTimer.stop()
        zombieWaveTimer.stop()
        exitRequested()
    }

    Component.onCompleted: {
        var hasLoaded = loadSavedGame()
        if (!hasLoaded) {
            startNewGame(1)
        }
    }

    Component.onDestruction: {
        saveGame()
    }

    // --- Touch / Planting Interaction ---
    function selectCard(idx) {
        if (shovelMode) shovelMode = false
        if (selectedPlantIdx === idx) {
            selectedPlantIdx = -1
            return
        }
        var card = plantCards[idx]
        if (sun < card.cost) {
            showToast("⚠️ 阳光不足 (" + sun + "/" + card.cost + ")")
            return
        }
        if (cardCooldowns[idx] > 0) {
            showToast("⏳ 冷却中，请稍候…")
            return
        }
        selectedPlantIdx = idx
    }

    function selectShovel() {
        selectedPlantIdx = -1
        shovelMode = !shovelMode
    }

    function handleTileClick(r, c) {
        if (!gameRunning || gamePaused) return

        // 1. Shovel mode: dig up plant
        if (shovelMode) {
            var pIdx = findPlantAt(r, c)
            if (pIdx >= 0) {
                var updated = gridPlants.slice()
                updated.splice(pIdx, 1)
                gridPlants = updated
                showToast("铲除了植物")
            }
            shovelMode = false
            return
        }

        // 2. Planting mode
        if (selectedPlantIdx >= 0) {
            if (findPlantAt(r, c) >= 0) {
                showToast("此处已有植物")
                return
            }
            var card = plantCards[selectedPlantIdx]
            if (sun < card.cost) {
                showToast("阳光不足！")
                selectedPlantIdx = -1
                return
            }

            // Deduct sun & start cooldown
            sun -= card.cost
            var newCooldowns = cardCooldowns.slice()
            newCooldowns[selectedPlantIdx] = 1.0
            cardCooldowns = newCooldowns

            // Add plant to grid
            var newPlant = {
                row: r,
                col: c,
                type: card.id,
                name: card.name,
                hp: card.hp,
                maxHp: card.hp,
                icon: card.icon,
                color: card.color,
                shootTimer: 0,
                sunTimer: 0,
                armTimer: card.id === "potatomine" ? 0 : 99,
                fuseTimer: card.id === "cherrybomb" ? 0 : 99,
                digestTimer: 0,
                state: card.id === "potatomine" ? "arming" : "idle"
            }
            var pList = gridPlants.slice()
            pList.push(newPlant)
            gridPlants = pList

            selectedPlantIdx = -1
            createFloatText(c * cellWidth + 40, r * cellHeight + 20, card.name, "#10B981")
        }
    }

    function findPlantAt(r, c) {
        for (var i = 0; i < gridPlants.length; i++) {
            if (gridPlants[i].row === r && gridPlants[i].col === c) return i
        }
        return -1
    }

    function spawnSun(x, y, val) {
        var sunObj = {
            id: Date.now() + Math.random(),
            x: x,
            y: y,
            targetY: Math.min(y + 120, lawnArea.height - 70),
            val: val || 25,
            isFalling: true,
            opacity: 1.0
        }
        var sList = sunsList.slice()
        sList.push(sunObj)
        sunsList = sList
    }

    function collectSun(idx) {
        if (idx < 0 || idx >= sunsList.length) return
        var s = sunsList[idx]
        sun += s.val
        createFloatText(s.x, s.y, "+" + s.val, "#F59E0B")
        var sList = sunsList.slice()
        sList.splice(idx, 1)
        sunsList = sList
    }

    // --- Main Game Engine Tick (60 FPS / 16ms) ---
    Timer {
        id: gameLoopTimer
        interval: 16
        repeat: true
        running: pvzPage.gameRunning && !pvzPage.gamePaused
        onTriggered: pvzPage.updateGameEngine()
    }

    function updateGameEngine() {
        var dt = 0.016 * gameSpeed

        // 1. Update Card Cooldowns
        var cds = cardCooldowns.slice()
        var cdChanged = false
        for (var c = 0; c < cds.length; c++) {
            if (cds[c] > 0) {
                cds[c] = Math.max(0, cds[c] - (dt / plantCards[c].cd))
                cdChanged = true
            }
        }
        if (cdChanged) cardCooldowns = cds

        // 2. Update Plants (Shooting, Sun generation, Explosions, Digestion)
        var updatedPlants = []
        for (var pi = 0; pi < gridPlants.length; pi++) {
            var p = Object.assign({}, gridPlants[pi])

            // Sunflower generates sun
            if (p.type === "sunflower") {
                p.sunTimer += dt
                if (p.sunTimer >= 10.0) {
                    p.sunTimer = 0
                    spawnSun(p.col * cellWidth + 24, p.row * cellHeight + 10, 25)
                }
            }

            // Peashooter & Repeater & Snowpea check for zombies in row
            if (p.type === "peashooter" || p.type === "snowpea" || p.type === "repeater") {
                var hasZombieInFront = false
                for (var zi = 0; zi < zombiesList.length; zi++) {
                    if (zombiesList[zi].row === p.row && zombiesList[zi].x > (p.col * cellWidth + 20)) {
                        hasZombieInFront = true
                        break
                    }
                }
                if (hasZombieInFront) {
                    p.shootTimer += dt
                    var shootInterval = (p.type === "repeater") ? 1.2 : 1.4
                    if (p.shootTimer >= shootInterval) {
                        p.shootTimer = 0
                        // Spawn projectile
                        var proj = {
                            id: Date.now() + Math.random(),
                            row: p.row,
                            x: p.col * cellWidth + 60,
                            y: p.row * cellHeight + 34,
                            type: p.type === "snowpea" ? "snow" : "pea",
                            damage: 20,
                            speed: 380 * dt
                        }
                        var pList = projectilesList.slice()
                        pList.push(proj)
                        if (p.type === "repeater") {
                            // 2nd pea slightly behind
                            pList.push({
                                id: Date.now() + Math.random() + 1,
                                row: p.row,
                                x: p.col * cellWidth + 35,
                                y: p.row * cellHeight + 34,
                                type: "pea",
                                damage: 20,
                                speed: 380 * dt
                            })
                        }
                        projectilesList = pList
                    }
                }
            }

            // Potato Mine: Arming in 10s, then arms
            if (p.type === "potatomine" && p.state === "arming") {
                p.armTimer += dt
                if (p.armTimer >= 8.0) {
                    p.state = "armed"
                    createFloatText(p.col * cellWidth + 30, p.row * cellHeight + 10, "SPUDOW!", "#84CC16")
                }
            }

            // Cherry Bomb: Countdown 1.2s -> Explodes 3x3
            if (p.type === "cherrybomb") {
                p.fuseTimer += dt
                if (p.fuseTimer >= 1.2) {
                    // Explode 3x3
                    explodeCherryBomb(p.row, p.col)
                    continue // Plant is destroyed after exploding
                }
            }

            // Chomper digestion countdown
            if (p.type === "chomper") {
                if (p.state === "digesting") {
                    p.digestTimer -= dt
                    if (p.digestTimer <= 0) p.state = "idle"
                } else {
                    // Try to swallow zombie in front (within 1.2 tiles)
                    for (var czi = 0; czi < zombiesList.length; czi++) {
                        var cz = zombiesList[czi]
                        if (cz.row === p.row && cz.x >= (p.col * cellWidth) && cz.x <= (p.col * cellWidth + 110)) {
                            // Swallow zombie!
                            killZombie(czi, "swallowed")
                            p.state = "digesting"
                            p.digestTimer = 15.0
                            createFloatText(p.col * cellWidth + 30, p.row * cellHeight + 10, "CHOMP!", "#8B5CF6")
                            break
                        }
                    }
                }
            }

            // Only keep alive plants
            if (p.hp > 0) {
                updatedPlants.push(p)
            }
        }
        gridPlants = updatedPlants

        // 3. Update Projectiles
        var updatedProj = []
        for (var pr = 0; pr < projectilesList.length; pr++) {
            var bullet = Object.assign({}, projectilesList[pr])
            bullet.x += bullet.speed

            var hitZombie = false
            for (var zIndex = 0; zIndex < zombiesList.length; zIndex++) {
                var targetZombie = zombiesList[zIndex]
                if (targetZombie.row === bullet.row && Math.abs(bullet.x - (targetZombie.x + 35)) < 24) {
                    // Hit!
                    hitZombie = true
                    damageZombie(zIndex, bullet.damage, bullet.type === "snow")
                    break
                }
            }

            // Remove if hit or out of screen
            if (!hitZombie && bullet.x < lawnArea.width) {
                updatedProj.push(bullet)
            }
        }
        projectilesList = updatedProj

        // 4. Update Zombies (Walking, Eating plants, Potato mine trigger, Lawn Mower breach)
        var updatedZombies = []
        for (var z = 0; z < zombiesList.length; z++) {
            var zom = Object.assign({}, zombiesList[z])

            // Slow timer countdown
            if (zom.isFrozen) {
                zom.freezeTimer -= dt
                if (zom.freezeTimer <= 0) zom.isFrozen = false
            }

            // Check if standing on armed Potato Mine
            var myCol = Math.floor((zom.x + 30) / cellWidth)
            if (myCol >= 0 && myCol < gridCols) {
                var mineIdx = findPlantAt(zom.row, myCol)
                if (mineIdx >= 0 && gridPlants[mineIdx].type === "potatomine" && gridPlants[mineIdx].state === "armed") {
                    // BOOM!
                    createFloatText(zom.x, zom.row * cellHeight + 10, "💥 BOOM!", "#EF4444")
                    damageZombie(z, 1800, false)
                    // Remove mine
                    var gPlants = gridPlants.slice()
                    gPlants.splice(mineIdx, 1)
                    gridPlants = gPlants
                    continue
                }
            }

            // Check if eating a plant in front
            var plantIdx = findPlantAt(zom.row, myCol)
            if (plantIdx >= 0 && (zom.x >= myCol * cellWidth - 10) && (zom.x <= myCol * cellWidth + 50)) {
                zom.isEating = true
                var targetPlant = gridPlants[plantIdx]
                targetPlant.hp -= 50 * dt // 50 dmg/sec
                if (targetPlant.hp <= 0) {
                    // Plant destroyed
                    var remainingPlants = gridPlants.slice()
                    remainingPlants.splice(plantIdx, 1)
                    gridPlants = remainingPlants
                    zom.isEating = false
                }
            } else {
                zom.isEating = false
            }

            // Move zombie forward if not eating
            if (!zom.isEating) {
                var actualSpeed = zom.speed * (zom.isFrozen ? 0.5 : 1.0)
                if (zom.isRaged) actualSpeed *= 2.2
                zom.x -= actualSpeed * 60 * dt
            }

            // Check Lawn Mower trigger at left edge (x <= 15)
            if (zom.x <= 15) {
                if (lawnMowers[zom.row]) {
                    // Trigger Lawn Mower!
                    startLawnMower(zom.row)
                } else if (zom.x <= -30) {
                    // Zombie entered house! Game Over!
                    triggerGameOver()
                    return
                }
            }

            if (zom.hp > 0) {
                updatedZombies.push(zom)
            }
        }
        zombiesList = updatedZombies

        // 5. Update Running Lawn Mowers
        var mPositions = mowerPositions.slice()
        var mMowers = lawnMowers.slice()
        for (var mr = 0; mr < 5; mr++) {
            if (mPositions[mr] >= 0) {
                mPositions[mr] += 750 * dt // Fast charge across lane
                // Kill any zombies in lane touched by mower
                for (var zi = 0; zi < zombiesList.length; zi++) {
                    if (zombiesList[zi].row === mr && zombiesList[zi].x <= mPositions[mr] + 40) {
                        damageZombie(zi, 9999, false)
                    }
                }
                if (mPositions[mr] > lawnArea.width + 100) {
                    mPositions[mr] = -99 // Offscreen finished
                    mMowers[mr] = false
                }
            }
        }
        mowerPositions = mPositions
        lawnMowers = mMowers

        // 6. Update Sun Drops
        var updatedSuns = []
        for (var s = 0; s < sunsList.length; s++) {
            var sunItem = Object.assign({}, sunsList[s])
            if (sunItem.isFalling) {
                sunItem.y += 65 * dt
                if (sunItem.y >= sunItem.targetY) {
                    sunItem.isFalling = false
                }
            }
            updatedSuns.push(sunItem)
        }
        sunsList = updatedSuns

        // 7. Check Level Win Condition
        if (wave >= maxWaves && zombiesList.length === 0 && waveProgress >= 1.0) {
            triggerGameWon()
        }
    }

    // --- Combat Helpers ---
    function damageZombie(index, dmg, freeze) {
        if (index < 0 || index >= zombiesList.length) return
        var zList = zombiesList.slice()
        var z = Object.assign({}, zList[index])
        z.hp -= dmg

        if (freeze) {
            z.isFrozen = true
            z.freezeTimer = 4.0
        }

        // Newspaper Zombie Rage Check
        if (z.type === "newspaper" && z.hp <= 200 && !z.isRaged) {
            z.isRaged = true
            createFloatText(z.x, z.row * cellHeight + 10, "GRRR!", "#EF4444")
        }

        if (z.hp <= 0) {
            score += (z.type === "buckethead" ? 50 : (z.type === "conehead" ? 30 : 20))
            zList.splice(index, 1)
        } else {
            zList[index] = z
        }
        zombiesList = zList
    }

    function killZombie(index, reason) {
        if (index < 0 || index >= zombiesList.length) return
        var zList = zombiesList.slice()
        score += 20
        zList.splice(index, 1)
        zombiesList = zList
    }

    function explodeCherryBomb(r, c) {
        createFloatText(c * cellWidth + 20, r * cellHeight + 10, "💥 BOOM!", "#EF4444")
        for (var z = zombiesList.length - 1; z >= 0; z--) {
            var zom = zombiesList[z]
            var zCol = Math.floor(zom.x / cellWidth)
            if (Math.abs(zom.row - r) <= 1 && Math.abs(zCol - c) <= 1) {
                damageZombie(z, 1800, false)
            }
        }
    }

    function startLawnMower(row) {
        var mPositions = mowerPositions.slice()
        if (mPositions[row] < 0) {
            mPositions[row] = 0
            mowerPositions = mPositions
            createFloatText(40, row * cellHeight + 20, "除草机启动！", "#10B981")
        }
    }

    function triggerGameOver() {
        gameOver = true
        gameRunning = false
        clearSave()
        showToast("💀 僵尸吃掉了你的脑子！")
    }

    function triggerGameWon() {
        gameWon = true
        gameRunning = false
        clearSave()
        showToast("🎉 恭喜！你成功守护了草坪！")
    }

    // --- Natural Sun Drop Spawner ---
    Timer {
        id: sunDropTimer
        interval: 9000
        repeat: true
        running: pvzPage.gameRunning && !pvzPage.gamePaused
        onTriggered: {
            var dropX = 80 + Math.random() * (lawnArea.width - 200)
            pvzPage.spawnSun(dropX, 10, 25)
        }
    }

    // --- Zombie Wave Spawner ---
    Timer {
        id: zombieWaveTimer
        interval: 7000
        repeat: true
        running: pvzPage.gameRunning && !pvzPage.gamePaused
        onTriggered: pvzPage.spawnNextZombie()
    }

    function spawnNextZombie() {
        waveProgress = Math.min(1.0, waveProgress + 0.15)
        if (waveProgress >= 1.0 && wave < maxWaves) {
            wave++
            waveProgress = 0.0
            showToast("⚠️ 一大波僵尸正在来袭！(波次 " + wave + "/" + maxWaves + ")")
            // Huge wave spawn
            spawnZombieRow(Math.floor(Math.random() * 5), "flag")
            spawnZombieRow(Math.floor(Math.random() * 5), "conehead")
            spawnZombieRow(Math.floor(Math.random() * 5), "buckethead")
            return
        }

        // Standard wave spawn
        var randomRow = Math.floor(Math.random() * 5)
        var types = ["regular", "regular", "conehead"]
        if (level >= 2) types.push("newspaper", "buckethead")
        if (level >= 3) types.push("football")
        var chosenType = types[Math.floor(Math.random() * types.length)]
        spawnZombieRow(randomRow, chosenType)
    }

    function spawnZombieRow(r, type) {
        var baseHp = 200
        var baseSpeed = 0.45
        var icon = "🧟"

        if (type === "conehead") { baseHp = 560; icon = "🍦"; }
        else if (type === "buckethead") { baseHp = 1100; icon = "🪣"; }
        else if (type === "newspaper") { baseHp = 350; icon = "📰"; }
        else if (type === "flag") { baseHp = 200; baseSpeed = 0.65; icon = "🚩"; }
        else if (type === "football") { baseHp = 1400; baseSpeed = 0.95; icon = "🏈"; }

        var newZombie = {
            id: Date.now() + Math.random(),
            row: r,
            x: lawnArea.width + 10 + Math.random() * 40,
            type: type,
            icon: icon,
            hp: baseHp,
            maxHp: baseHp,
            speed: baseSpeed,
            isEating: false,
            isFrozen: false,
            freezeTimer: 0,
            isRaged: false
        }
        var zList = zombiesList.slice()
        zList.push(newZombie)
        zombiesList = zList
    }

    // --- Floating Text Overlay Particles ---
    property var floatTexts: []
    function createFloatText(x, y, txt, col) {
        var list = floatTexts.slice()
        list.push({ id: Date.now() + Math.random(), x: x, y: y, text: txt, color: col, opacity: 1.0 })
        floatTexts = list
    }

    Timer {
        interval: 50
        repeat: true
        running: pvzPage.floatTexts.length > 0
        onTriggered: {
            var updated = []
            for (var i = 0; i < pvzPage.floatTexts.length; i++) {
                var item = Object.assign({}, pvzPage.floatTexts[i])
                item.y -= 2
                item.opacity -= 0.05
                if (item.opacity > 0) updated.push(item)
            }
            pvzPage.floatTexts = updated
        }
    }

    // ==========================================
    // UI LAYOUT
    // ==========================================

    // 1. Top Global Header
    AppHeader {
        id: appHeader
        title: "植物大战僵尸"
        subtitle: "第 " + pvzPage.level + " 关 · 波次 " + pvzPage.wave + "/" + pvzPage.maxWaves
        showBack: false
        trailingText: "得分 " + pvzPage.score
        onExitRequested: pvzPage.exitGame()
    }

    // 2. Main Game Body
    Item {
        anchors { top: appHeader.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }

        // --- A. Top Plant Card Deck & Sun Bank ---
        Rectangle {
            id: deckBar
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
            height: 84; radius: 18
            color: "#0F172A"; border.color: "#334155"; border.width: 1

            RowLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 10

                // Sunlight Bank
                Rectangle {
                    Layout.preferredWidth: 100; Layout.fillHeight: true; radius: 14
                    color: "#FEF3C7"; border.color: "#FDE68A"; border.width: 1
                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: "☀️"; font.pixelSize: 24 }
                        Text {
                            text: pvzPage.sun
                            color: "#B45309"; font.family: window.uiFont; font.pixelSize: 22; font.weight: Font.Bold
                        }
                    }
                }

                // Plant Cards Repeater
                Row {
                    Layout.fillWidth: true; Layout.fillHeight: true; spacing: 6
                    Repeater {
                        model: pvzPage.plantCards
                        delegate: Rectangle {
                            id: cardBtn
                            width: 82; height: parent.height; radius: 12
                            color: pvzPage.selectedPlantIdx === index ? "#3B82F6" : (pvzPage.sun >= modelData.cost && pvzPage.cardCooldowns[index] === 0 ? "#1E293B" : "#0F172A")
                            border.color: pvzPage.selectedPlantIdx === index ? "#60A5FA" : (pvzPage.sun >= modelData.cost ? "#475569" : "#1E293B")
                            border.width: pvzPage.selectedPlantIdx === index ? 2 : 1
                            opacity: pvzPage.sun >= modelData.cost && pvzPage.cardCooldowns[index] === 0 ? 1.0 : 0.65

                            Column {
                                anchors.centerIn: parent; spacing: 2
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.icon; font.pixelSize: 22 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; color: "#E2E8F0"; font.family: window.uiFont; font.pixelSize: 11; font.weight: Font.DemiBold }
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 44; height: 16; radius: 6; color: "#0284C7"
                                    Text { anchors.centerIn: parent; text: modelData.cost; color: "white"; font.family: window.uiFont; font.pixelSize: 10; font.weight: Font.Bold }
                                }
                            }

                            // Cooldown overlay sweep
                            Rectangle {
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                height: parent.height * pvzPage.cardCooldowns[index]
                                radius: 12; color: "#000000"; opacity: 0.55
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: pvzPage.selectCard(index)
                            }
                        }
                    }
                }

                // Shovel Tool
                Rectangle {
                    Layout.preferredWidth: 64; Layout.fillHeight: true; radius: 14
                    color: pvzPage.shovelMode ? "#EF4444" : "#1E293B"
                    border.color: pvzPage.shovelMode ? "#F87171" : "#475569"; border.width: 1
                    Column {
                        anchors.centerIn: parent; spacing: 1
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "⛏️"; font.pixelSize: 20 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "铲子"; color: "#E2E8F0"; font.family: window.uiFont; font.pixelSize: 11; font.weight: Font.DemiBold }
                    }
                    MouseArea { anchors.fill: parent; onClicked: pvzPage.selectShovel() }
                }

                // Auto-save Badge & Controls
                ColumnLayout {
                    Layout.preferredWidth: 120; Layout.fillHeight: true; spacing: 4
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 28; radius: 8
                        color: "#065F46"; border.color: "#10B981"; border.width: 1
                        Row {
                            anchors.centerIn: parent; spacing: 4
                            Text { text: "💾"; font.pixelSize: 12 }
                            Text { text: "自动存档中"; color: "#A7F3D0"; font.family: window.uiFont; font.pixelSize: 11; font.weight: Font.DemiBold }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 4
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 26; radius: 6
                            color: pvzPage.gameSpeed > 1 ? "#D97706" : "#334155"
                            Text { anchors.centerIn: parent; text: pvzPage.gameSpeed > 1 ? "2x 倍速" : "1x 正常"; color: "white"; font.family: window.uiFont; font.pixelSize: 11 }
                            MouseArea { anchors.fill: parent; onClicked: pvzPage.gameSpeed = pvzPage.gameSpeed > 1 ? 1.0 : 2.0 }
                        }
                        Rectangle {
                            Layout.preferredWidth: 32; Layout.preferredHeight: 26; radius: 6
                            color: "#334155"
                            Text { anchors.centerIn: parent; text: pvzPage.gamePaused ? "▶" : "⏸"; color: "white"; font.pixelSize: 12 }
                            MouseArea { anchors.fill: parent; onClicked: pvzPage.gamePaused = !pvzPage.gamePaused }
                        }
                    }
                }
            }
        }

        // --- B. Lawn Battlefield Arena ---
        Rectangle {
            id: lawnArea
            anchors { top: deckBar.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; margins: 12; topMargin: 8 }
            radius: 20; color: "#064E3B"; clip: true
            border.color: "#047857"; border.width: 2

            // 5x9 Checkerboard Lawn Grid
            Grid {
                anchors.left: parent.left; anchors.leftMargin: 64
                anchors.top: parent.top; anchors.topMargin: 12
                rows: pvzPage.gridRows; columns: pvzPage.gridCols
                spacing: 2

                Repeater {
                    model: pvzPage.gridRows * pvzPage.gridCols
                    delegate: Rectangle {
                        readonly property int r: Math.floor(index / pvzPage.gridCols)
                        readonly property int c: index % pvzPage.gridCols
                        width: pvzPage.cellWidth; height: pvzPage.cellHeight; radius: 10
                        color: (r + c) % 2 === 0 ? "#10B981" : "#059669"
                        border.color: tileMouse.containsMouse && pvzPage.selectedPlantIdx >= 0 ? "#FDE047" : "transparent"
                        border.width: 2

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: pvzPage.handleTileClick(r, c)
                        }
                    }
                }
            }

            // 5 Lawn Mowers on Left Column (x: 8)
            Repeater {
                model: 5
                delegate: Rectangle {
                    readonly property int mowerRow: index
                    readonly property double posX: pvzPage.mowerPositions[mowerRow] >= 0 ? (64 + pvzPage.mowerPositions[mowerRow]) : 12
                    visible: pvzPage.lawnMowers[mowerRow] || pvzPage.mowerPositions[mowerRow] >= 0
                    x: posX; y: 12 + mowerRow * (pvzPage.cellHeight + 2) + 22
                    width: 48; height: 52; radius: 12
                    color: "#DC2626"; border.color: "#F87171"; border.width: 2
                    Column {
                        anchors.centerIn: parent; spacing: 1
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🚜"; font.pixelSize: 22 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "割草机"; color: "white"; font.family: window.uiFont; font.pixelSize: 8; font.weight: Font.Bold }
                    }
                }
            }

            // Plants Layer
            Repeater {
                model: pvzPage.gridPlants
                delegate: Item {
                    x: 64 + modelData.col * (pvzPage.cellWidth + 2)
                    y: 12 + modelData.row * (pvzPage.cellHeight + 2)
                    width: pvzPage.cellWidth; height: pvzPage.cellHeight

                    // Plant Avatar
                    Column {
                        anchors.centerIn: parent; spacing: 1
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.icon
                            font.pixelSize: modelData.type === "wallnut" ? 36 : 30
                            scale: modelData.type === "cherrybomb" ? (1.0 + modelData.fuseTimer * 0.5) : 1.0
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.type === "chomper" && modelData.state === "digesting" ? "咀嚼中…" : modelData.name
                            color: "#FFFFFF"; font.family: window.uiFont; font.pixelSize: 11; font.weight: Font.Bold
                        }
                        // Health Bar (for wall-nut or damaged plants)
                        Rectangle {
                            visible: modelData.hp < modelData.maxHp
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 50; height: 5; radius: 2.5; color: "#374151"
                            Rectangle {
                                width: Math.max(2, parent.width * (modelData.hp / modelData.maxHp))
                                height: parent.height; radius: parent.radius
                                color: modelData.hp > (modelData.maxHp * 0.5) ? "#10B981" : "#EF4444"
                            }
                        }
                    }
                }
            }

            // Projectiles Layer
            Repeater {
                model: pvzPage.projectilesList
                delegate: Rectangle {
                    x: 64 + modelData.x; y: 12 + modelData.y
                    width: 18; height: 18; radius: 9
                    color: modelData.type === "snow" ? "#38BDF8" : "#4ADE80"
                    border.color: modelData.type === "snow" ? "#E0F2FE" : "#BBF7D0"; border.width: 2
                }
            }

            // Zombies Layer
            Repeater {
                model: pvzPage.zombiesList
                delegate: Item {
                    x: 64 + modelData.x
                    y: 12 + modelData.row * (pvzPage.cellHeight + 2) + 6
                    width: 60; height: pvzPage.cellHeight - 12

                    // Zombie Avatar & Armor
                    Column {
                        anchors.centerIn: parent; spacing: 1
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.icon
                            font.pixelSize: 34
                            opacity: modelData.isFrozen ? 0.75 : 1.0
                        }
                        // Health Bar
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 44; height: 5; radius: 2.5; color: "#1F2937"
                            Rectangle {
                                width: Math.max(2, parent.width * (modelData.hp / modelData.maxHp))
                                height: parent.height; radius: parent.radius
                                color: modelData.isFrozen ? "#38BDF8" : (modelData.isRaged ? "#EF4444" : "#F59E0B")
                            }
                        }
                    }
                }
            }

            // Natural & Generated Suns Layer
            Repeater {
                model: pvzPage.sunsList
                delegate: Rectangle {
                    x: 64 + modelData.x; y: 12 + modelData.y
                    width: 52; height: 52; radius: 26
                    color: "#FBBF24"; border.color: "#FEF08A"; border.width: 3
                    opacity: modelData.opacity

                    Text { anchors.centerIn: parent; text: "☀️"; font.pixelSize: 28 }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: pvzPage.collectSun(index)
                    }
                }
            }

            // Floating Text Particles
            Repeater {
                model: pvzPage.floatTexts
                delegate: Text {
                    x: 64 + modelData.x; y: 12 + modelData.y
                    text: modelData.text
                    color: modelData.color
                    font.family: window.uiFont; font.pixelSize: 18; font.weight: Font.Bold
                    opacity: modelData.opacity
                }
            }

            // Bottom Wave Progress Pill
            Rectangle {
                anchors { right: parent.right; bottom: parent.bottom; margins: 16 }
                width: 220; height: 32; radius: 16
                color: "#0F172A"; border.color: "#334155"; border.width: 1

                RowLayout {
                    anchors.fill: parent; anchors.margins: 6; spacing: 8
                    Text { text: "🧟"; font.pixelSize: 16 }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 8; radius: 4; color: "#1E293B"
                        Rectangle {
                            width: parent.width * pvzPage.waveProgress
                            height: parent.height; radius: parent.radius; color: "#EF4444"
                        }
                    }
                    Text { text: "波次 " + pvzPage.wave + "/" + pvzPage.maxWaves; color: "#CBD5E1"; font.family: window.uiFont; font.pixelSize: 11; font.weight: Font.Bold }
                }
            }
        }
    }

    // 3. Floating Toast Banner
    Rectangle {
        anchors { top: parent.top; topMargin: 70; horizontalCenter: parent.horizontalCenter }
        width: toastLabel.implicitWidth + 36; height: 38; radius: 19
        color: "#0F172A"; border.color: "#3B82F6"; border.width: 1
        opacity: pvzPage.toastVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        Text {
            id: toastLabel
            anchors.centerIn: parent
            text: pvzPage.toastText
            color: "#F8FAFC"; font.family: window.uiFont; font.pixelSize: 14; font.weight: Font.DemiBold
        }
    }

    // 4. Game Over / Victory Modal Dialog
    Rectangle {
        anchors.fill: parent
        visible: pvzPage.gameOver || pvzPage.gameWon
        color: "#CC000000"

        Rectangle {
            anchors.centerIn: parent
            width: 480; height: 280; radius: 24
            color: "#1E293B"; border.color: pvzPage.gameWon ? "#10B981" : "#EF4444"; border.width: 2

            Column {
                anchors.centerIn: parent; spacing: 18

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: pvzPage.gameWon ? "🎉 守护草坪大获全胜！" : "💀 僵尸入侵！挑战失败"
                    color: pvzPage.gameWon ? "#34D399" : "#F87171"
                    font.family: window.uiFont; font.pixelSize: 26; font.weight: Font.Bold
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "最终得分: " + pvzPage.score + "  ·  关卡 " + pvzPage.level
                    color: "#94A3B8"; font.family: window.uiFont; font.pixelSize: 16
                }

                RowLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    Button {
                        text: pvzPage.gameWon ? "下一关 ➜" : "再战一次 🔄"
                        font.family: window.uiFont; font.pixelSize: 16; font.weight: Font.Bold
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
                        background: Rectangle { implicitWidth: 150; implicitHeight: 46; radius: 14; color: pvzPage.gameWon ? "#059669" : "#DC2626" }
                        onClicked: pvzPage.startNewGame(pvzPage.gameWon ? pvzPage.level + 1 : pvzPage.level)
                    }

                    Button {
                        text: "退出应用"
                        font.family: window.uiFont; font.pixelSize: 16; font.weight: Font.Bold
                        contentItem: Text { text: parent.text; color: "#CBD5E1"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
                        background: Rectangle { implicitWidth: 120; implicitHeight: 46; radius: 14; color: "#334155" }
                        onClicked: pvzPage.exitGame()
                    }
                }
            }
        }
    }
}
