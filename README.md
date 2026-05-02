# 👁️ LocalhostWatcher

> **Keep your localhost apps visible, healthy, and easy to reopen.** A lightweight macOS menu bar app that monitors your local development servers.

[![Download](https://img.shields.io/badge/Download-macOS%20.dmg-0c8ce9?style=for-the-badge&logo=apple)](https://github.com/dot-RealityTest/LocalhostWatcher/releases/download/v1.0/LocalhostWatcher-1.0.dmg)
[![Release](https://img.shields.io/github/v/release/dot-RealityTest/LocalhostWatcher?style=for-the-badge&logo=github)](https://github.com/dot-RealityTest/LocalhostWatcher/releases/tag/v1.0)
[![Website](https://img.shields.io/badge/Website-akakika.com-38bdf8?style=for-the-badge&logo=vercel)](https://akakika.com/localhostwatcher/)

---

## 🌐 Get It Now

**Website:** [https://akakika.com/localhostwatcher/](https://akakika.com/localhostwatcher/)  
**Download:** [LocalhostWatcher-1.0.dmg](https://github.com/dot-RealityTest/LocalhostWatcher/releases/download/v1.0/LocalhostWatcher-1.0.dmg)

---

## 💡 The Problem

You're running multiple local development servers:
- React app on `:3000`
- API on `:8080`
- Database on `:5432`
- Redis on `:6379`

Which ones are actually running? Which ones crashed? Which ports are available?

Checking each one manually is tedious. Activity Monitor is overwhelming. Terminal commands are forgettable.

---

## ✨ The Solution

**LocalhostWatcher** lives quietly in your menu bar and keeps track of everything for you.

- ✅ Auto-discovers active localhost services
- ✅ Health-checks each port to see if it's responding
- ✅ Shows unhealthy services at a glance
- ✅ Quick open/stop actions from menu bar
- ✅ Optional auto-relaunch on login

No configuration needed. Just install and it works.

---

## 🚀 Features

| Feature | Description |
|---------|-------------|
| **🔍 Auto-Discovery** | Scans common development ports automatically |
| **💚 Health Checks** | HTTP requests to verify services are responding |
| **🔴 Status Indicators** | Visual feedback for healthy/unhealthy services |
| **⚡ Quick Actions** | Open or stop services with one click |
| **🔄 Auto-Relaunch** | Save selected apps to restart on login |
| **📊 Menu Bar Dashboard** | At-a-glance view of all your services |
| **🔒 Local-Only** | No data leaves your machine |

---

## 📋 What It Monitors

LocalhostWatcher automatically scans common development ports:

- **Web Servers:** 3000, 3001, 8000, 8080, 8888
- **Databases:** 5432 (PostgreSQL), 3306 (MySQL), 27017 (MongoDB)
- **Cache:** 6379 (Redis), 11211 (Memcached)
- **API Servers:** 4000, 5000, 8001, 9000
- **Custom:** Add your own ports

---

## 🎬 How It Works

### 1️⃣ Install & Launch
Download the DMG, drag to Applications, and launch.

### 2️⃣ Auto-Discovery
LocalhostWatcher scans for active ports and identifies the processes behind them.

### 3️⃣ Health Check
Each service gets an HTTP health check to verify it's responding.

### 4️⃣ Monitor & Manage
- **Green** = Healthy and responding
- **Red** = Port active but not responding
- **Gray** = No service detected

### 5️⃣ Quick Actions
Click to open in browser, stop the process, or mark for auto-relaunch.

---

## 🛠️ Tech Stack

- **Swift** + **SwiftUI** — Native macOS app
- **Menu Bar App** — Lightweight, always accessible
- **Network Scanning** — Port detection and health checks
- **Process Management** — Identify and control running services
- **Launch Agent** — Auto-relaunch on login

---

## 📥 Installation

### Download & Install

1. **[Download LocalhostWatcher-1.0.dmg](https://github.com/dot-RealityTest/LocalhostWatcher/releases/download/v1.0/LocalhostWatcher-1.0.dmg)**
2. Open the `.dmg` file
3. Drag LocalhostWatcher to Applications folder
4. Launch from Applications (or Spotlight: ⌘Space → "LocalhostWatcher")

### First Launch

- macOS may ask for confirmation — click "Open"
- Grant network permissions when prompted
- App appears in menu bar as 👁️ icon

---

## 🎯 Use Cases

### Web Developers
Monitor your React, Vue, or Next.js dev servers alongside your API backends.

### Full-Stack Engineers
Keep track of databases, caches, and microservices all in one place.

### DevOps
Quick health checks before deploying or testing integrations.

### Students
Learn what ports are active on your system and what they're running.

---

## ⚙️ Configuration

### Auto-Relaunch on Login

1. Open LocalhostWatcher from menu bar
2. Find the service you want to auto-start
3. Click the pin icon (📌)
4. Next login: LocalhostWatcher will relaunch it automatically

### Custom Ports

Edit the configuration file to add custom port ranges:
```json
{
  "customPorts": [9000, 9001, 9002]
}
```

---

## 🙋 FAQ

**Q: Does this slow down my system?**  
A: No! LocalhostWatcher is extremely lightweight. Health checks run every 30 seconds in the background.

**Q: Can it monitor remote servers?**  
A: No, LocalhostWatcher only monitors `localhost` (127.0.0.1) for security and privacy.

**Q: Does it work with Docker?**  
A: Yes! If your Docker containers expose ports to localhost, they'll be detected.

**Q: Is it free?**  
A: Yes, completely free.

**Q: What if a service requires authentication?**  
A: Health checks only verify the port is responding (HTTP 200/301/302). Authentication isn't required for basic status.

---

## 🔮 Roadmap

- [ ] Custom health check endpoints (e.g., `/health`)
- [ ] Notification alerts for service crashes
- [ ] Service groups (organize by project)
- [ ] Export service list to JSON/Markdown
- [ ] Dark mode customization
- [ ] Windows/Linux support

---

## 👨‍💻 Author

**KIKA** — Digital craft and macOS systems

- **Website:** https://akakika.com
- **Twitter:** [@Kika_Loren](https://twitter.com/Kika_Loren)
- **GitHub:** https://github.com/dot-RealityTest

---

## 📄 License

**Private** — All rights reserved to KIKA.

---

**Built with ❄️ by KIKA**  
**Last Updated:** May 2, 2026
