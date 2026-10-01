<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&height=190&color=0:05080D,45:0066FF,100:00D4FF&text=SzCore+Society&fontSize=42&fontColor=FFFFFF&animation=fadeIn&fontAlignY=38&desc=SzCore+Framework+%E2%80%A2+Organizations&descAlignY=60&descSize=16" width="100%" alt="SzCore Society" />
<img src="https://readme-typing-svg.demolab.com?font=Orbitron&weight=700&size=21&duration=2500&pause=850&color=00D4FF&center=true&vCenter=true&width=720&height=52&lines=Organizations;Modular+%E2%80%A2+Server-Authoritative+%E2%80%A2+Developer+First" alt="SzCore Society animated headline" />

<p><b>Organization and boss-management system for jobs and gangs with members, grades, society accounts and transaction history.</b></p>
<p>
<img src="https://img.shields.io/badge/SzCore-v1.4.0--rc1-8B5CF6?style=for-the-badge" alt="Version">
<img src="https://img.shields.io/badge/Type-Organizations-00D4FF?style=for-the-badge" alt="Type">
<img src="https://img.shields.io/badge/FiveM-Resource-F40552?style=for-the-badge&logo=fivem&logoColor=white" alt="FiveM">
<img src="https://img.shields.io/badge/Lua-5.4-2C2D72?style=for-the-badge&logo=lua&logoColor=white" alt="Lua">
</p>
<p>
<a href="https://github.com/Szilko121/szcore_society/stargazers"><img src="https://img.shields.io/github/stars/Szilko121/szcore_society?style=flat-square&logo=github&color=00D4FF" alt="Stars"></a>
<a href="https://github.com/Szilko121/szcore_society/issues"><img src="https://img.shields.io/github/issues/Szilko121/szcore_society?style=flat-square&logo=github&color=EF4444" alt="Issues"></a>
<img src="https://img.shields.io/github/last-commit/Szilko121/szcore_society?style=flat-square&logo=github&color=22C55E" alt="Last commit">
</p>
<p><a href="https://github.com/Szilko121/SzCore-Framework"><b>Framework</b></a> • <a href="https://github.com/Szilko121/SzCore-Framework/tree/main/docs"><b>Docs</b></a> • <a href="https://github.com/Szilko121/SzCore-Recipe"><b>Recipe</b></a> • <a href="https://github.com/Szilko121/szcore_society/issues"><b>Issues</b></a></p>
</div>

---

## 🚀 Overview

Organization and boss-management system for jobs and gangs with members, grades, society accounts and transaction history.

> Membership and financial mutations are checked and persisted on the server.

## ✨ Highlights

| | Capability |
|---:|---|
| ⚡ | **Boss/management interface** |
| 🧩 | **Online and offline members** |
| 🛡️ | **Nearby-player hiring** |
| 💾 | **Fire and grade management** |
| 🎯 | **Society bank account** |
| 🔌 | **Organization transaction history** |

## 📦 Installation

**Dependencies:** `oxmysql`, `szcore`, `szcore_ui`

```bash
git clone https://github.com/Szilko121/szcore_society.git "resources/[szcore]/szcore_society"
```

```cfg
ensure szcore_society
```

For a full deployment use **[SzCore-Recipe](https://github.com/Szilko121/SzCore-Recipe)**.

## 🔌 API Highlights

`EnsureSociety` · `GetSociety` · `Deposit` · `Withdraw` · `Hire` · `Fire` · `SetGrade` · `GetTransactions` · `OpenSociety`

## 🛡️ Engineering Principles

- Server authority for persistent or security-sensitive state.
- Explicit cross-resource APIs.
- Modular resource boundaries.
- Event-driven updates where practical.
- No fixed performance promise without a controlled benchmark.

## 🧩 Part of SzCore

<div align="center">
[![Framework](https://img.shields.io/badge/SzCore-Framework-00D4FF?style=for-the-badge&logo=github)](https://github.com/Szilko121/SzCore-Framework)
[![Recipe](https://img.shields.io/badge/txAdmin-Recipe-2563EB?style=for-the-badge&logo=github)](https://github.com/Szilko121/SzCore-Recipe)

<br><br><sub>Built by <b>SzCode</b> for the FiveM community.</sub>
<img src="https://capsule-render.vercel.app/api?type=waving&height=90&section=footer&color=0:00D4FF,55:0066FF,100:05080D" width="100%" alt="SzCore footer" />
</div>
