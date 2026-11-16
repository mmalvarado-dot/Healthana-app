# Healthana 💙 

Una aplicación móvil offline desarrollada en Flutter para el registro diario e intuitivo de síntomas médicos. Diseñada para ofrecer una experiencia de usuario rápida, privada y accesible sin necesidad de conexión a internet.

## 📱 Vistazo a la App
![Pantalla principal](assets/home.png)![Atajos](assets/recordaorios.png)

## 🚀 Características Principales
* **Registro de estado de ánimo:** Interfaz visual con selección dinámica de indicadores para medir el nivel de dolor o bienestar.
* **Dictado por Voz Offline:** Integración de *Speech-to-Text* nativo para facilitar la entrada de notas médicas sin necesidad de teclear.
* **Atajos de Texto Inteligentes:** Botones preconfigurados (ej. "Buen ánimo", "Sin dolor") para agilizar el llenado de reportes.
* **Almacenamiento Local Seguro:** Uso de SQLite para persistencia de datos 100% en el dispositivo, garantizando la privacidad absoluta del usuario.
* **Manejo de Estado Reactivo:** Implementación de `Provider` para actualizaciones fluidas y eficientes en la interfaz gráfica.

## 🛠️ Stack Tecnológico
* **Framework:** Flutter (Dart)
* **Gestor de Estado:** Provider
* **Base de Datos:** SQLite
* **Hardware & Sensores:** `speech_to_text` (Reconocimiento de voz nativo)

## 📂 Arquitectura y Buenas Prácticas
El proyecto sigue una separación clara de responsabilidades para asegurar un código limpio y escalable:
* `/screens`: Componentes visuales e interfaces de usuario rediseñadas.
* `/providers`: Lógica de negocio centralizada y manejo de estado.
* `/models`: Estructuras de datos fuertemente tipadas.
* `/services`: Interacción aislada con la base de datos local y dependencias del sistema.

## 🛣️ Próximos Pasos (Roadmap)
- [ ] Generación de reportes semanales exportables (PDF).
- [ ] Panel de métricas y gráficos de tendencias de salud.
- [ ] Soporte integral para modo oscuro (Dark Mode).

---
*Diseñado y desarrollado por [Tu Nombre] - [Enlace a tu perfil de LinkedIn]*