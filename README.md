# neBSPWM - Entorno de trabajo para Ciberseguridad

Mi espacio de trabajo para **ciberseguridad, hacking ético y desarrollo en Linux**.  

**Formateo mi equipo con frecuencia** y quería poder **restaurar mi entorno completo en minutos**, sin tener que volver a configurar cada detalle desde cero. Esta config esta pensada para mi trabajo en un **equipo modesto** (i3 de segunda generación y 8GB de RAM), por lo que diseñé esta configuración pensando en **rendimiento, ligereza y estabilidad**, sin sacrificar la estética ni la comodidad en largas jornadas de trabajo técnico.

El resultado es un entorno minimalista basado en **bspwm**, con **Rofi**, **Polybar**, **Conky**, **Kitty** y una paleta visual **Catppuccin Mocha**, pensado para mantenerse fluido incluso con múltiples herramientas de seguridad abiertas.

![Desktop](https://github.com/NeTenebraes/neBSPWM-dotfiles/blob/main/screeshots/Main.png)

> En resumen: **Una configuración que puedes reinstalar rápido, que se siente ágil en hardware antiguo, y que mantiene el mismo “flow” para programar, investigar y crear contenido.**

---

## Instalación

### Instalación del Entorno grafico
```
curl -sSL https://raw.githubusercontent.com/NeTenebraes/neBSPWM-dotfiles/main/setup.sh | bash
```
**Reiniciar:** `systemctl reboot`


### Instalación de herramientas Ciberseguridad.
```
curl -sSL https://raw.githubusercontent.com/NeTenebraes/neBSPWM-dotfiles/main/Cybersecurity.sh | bash
```
**Reiniciar:** `systemctl reboot`

### Manual
```
git clone https://github.com/NeTenebraes/neBSPWM-dotfiles.git
cd neBSPWM-dotfiles
./setup.sh
./Cybersecurity.sh
```
**Reiniciar:** `systemctl reboot`

---

## ✨ Características

- **Window Manager:** bspwm + sxhkd
- **Display Manager:** SDDM (tema netenebrae)
- **Launcher:** Rofi (drun mode)
- **Status Bar:** Polybar + Conky
- **Terminal:** Kitty + ZSH + Starship
- **Lock Screen:** betterlockscreen
- **Themes:** Catppuccin Mocha + Papirus Dark
- **Screenshots:** maim + xclip + notificaciones

## 📦 Requisitos

- Equipo basado en Arch Linux.
- `paru` (se instala automáticamente)
- ~2GB de espacio para dependencias

**El script instala y configura automáticamente:**
- bspwm, sxhkd, polybar, picom, rofi, dunst, kitty, conky
- sddm, zsh, starship, neovim, maim, betterlockscreen
- Temas GTK/qt Catppuccin + Papirus + Nerd Fonts

---

## 🖼️ Screenshots

| Componente | Vista |
|------------|-------|
| Escritorio | ![Main1](https://github.com/NeTenebraes/neBSPWM-dotfiles/blob/main/screeshots/Main1.png) |
| Escritorio | ![Main2](https://github.com/NeTenebraes/neBSPWM-dotfiles/blob/main/screeshots/Main2.png) |
| Rofi | ![Rofi](https://github.com/NeTenebraes/neBSPWM-dotfiles/blob/main/screeshots/Rofi.png) |
| Login Screen | ![SDDM](https://github.com/NeTenebraes/neBSPWM-dotfiles/blob/main/screeshots/SDDM.png) |

---

## 🧠 Script de Ciberseguridad

El archivo **`Cybersecurity.sh`** complementa este entorno, preparando Arch Linux para un flujo de trabajo orientado a **ciberseguridad, bug bounty y análisis de vulnerabilidades**. Su enfoque no es estético, sino funcional: **automatiza tareas técnicas que normalmente requerirían decenas de pasos manuales**.

### 🔍 Qué hace

- **Integra herramientas de seguridad** dentro del entorno gráfico existente, respetando la estética y el tema (íconos, entradas en Rofi, y configuraciones en `~/.local/share/applications`).
- **Instala y configura herramientas esenciales:**
  - **Burp Suite Community** → Proxy y escáner de tráfico HTTP/S, con un wrapper optimizado para Wayland/X11.
  - **Caido** → Proxy moderno alternativo a Burp, descargado dinámicamente desde GitHub y con integración directa en el menú de aplicaciones.
  - **Firejail** → Crea navegadores aislados. Agrega automáticamente accesos para *Navegador (Personal)* y *Navegador (Bug Bounty)* en Rofi, con red privada y DNS dedicados.
- **Virtualización configurada automáticamente:**
  - Detecta el kernel (hardened, LTS o Zen) e instala los headers adecuados.
  - Configura **VirtualBox** y **VMware Workstation** con módulos del kernel habilitados y red tipo *Host-Only* funcional por defecto, lista para entornos controlados o máquinas de laboratorio.
- **Configura red y protección general:**
  - Activa **UFW** con reglas predefinidas (Deny IN / Allow OUT).
  - Permite SSH de forma opcional.
  - Asigna resolutores DNS seguros a todo el equipo (Cloudflare, Quad9 o Google).
- **Automatiza el entorno de pentesting:** al finalizar, las herramientas quedan integradas en Rofi, el PATH del usuario, y listas para ejecutar sin elevación de privilegios.

```
chmod +x Cybersecurity.sh
./Cybersecurity.sh
```

> Ejecuta este script después de `setup.sh` para convertir tu entorno en un laboratorio de ciberseguridad completo, coherente en diseño, rendimiento y funcionalidad.

---
## ⚠️ Advertencia

Este script está pensado para una instalación limpia de Arch Linux (o derivados como Manjaro y EndeavourOS).  
Durante la ejecución se reemplaza el contenido de `~/.config/`, por lo que se recomienda **hacer una copia de seguridad de tu configuración actual antes de iniciarlo**. Al finalizar, **SDDM se habilita automáticamente** y todo el entorno queda listo para iniciar sesión en bspwm.
