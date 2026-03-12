# <img src="assets/logo.png" width="40" height="40" /> Ping Master Pro

![Version](https://img.shields.io/badge/version-1.0.8-00E676?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

O **Ping Master Pro** é um painel de monitoramento de rede de alta performance desenvolvido para técnicos e administradores que precisam de precisão em tempo real. O app combina uma estética *Pure Black* premium com ferramentas robustas de análise de estabilidade.

---

## ✨ Funcionalidades Key

- 🚀 **Monitoramento em Tempo Real:** Pings constantes com atualização a cada 5 segundos.
- 📊 **Gráficos Suaves:** Visualização de histórico através de curvas de Bezier e gradientes dinâmicos (Neon Green).
- 🔄 **Sistema OTA (Over-The-Air):** Receba atualizações e novos APKs diretamente dentro do aplicativo, sem precisar do navegador.
- 📉 **Detecção de Jitter:** Identifique instabilidades na rede antes que elas virem um problema.
- 💾 **Memória de Servidor:** O app lembra do seu último IP/Porta configurado automaticamente.
- 🎨 **Interface AMOLED Pro:** Design focado em baixo consumo de bateria e alta legibilidade em qualquer condição de luz.

---

## 📸 Screenshots

### 📱 Aplicativo Mobile
| Tela de Entrada (Login) | Dashboard Nativo |
| :---: | :---: |
| <img src="assets/screenshots/mobile_login.jpg" width="250" /> | <img src="assets/screenshots/mobile_dashboard.jpg" width="250" /> |

### 💻 Painel Web & Ferramentas
| Dashboard Web Profissional |
| :---: |
| <img src="assets/screenshots/web_dashboard.png" width="800" /> |

| Análise de Qualidade | Traceroute (Rota) |
| :---: | :---: |
| <img src="assets/screenshots/quality_analysis.png" width="400" /> | <img src="assets/screenshots/traceroute.png" width="400" /> |

---

## 🛠️ Tecnologias Utilizadas

- **Framework:** Flutter (Material 3)
- **Charts:** [fl_chart](https://pub.dev/packages/fl_chart)
- **Icons:** Font Awesome & Google Fonts (Outfit)
- **Networking:** Http & Dio
- **Storage:** Shared Preferences

---

## 📦 Como Instalar

### Usuários
1. Vá para a seção de **[Releases](https://github.com/devairfernandes/ping_master/releases)** deste repositório.
2. Baixe o APK mais recente (`app-arm64-v8a-release.apk`).
3. Instale no seu Android (permita a instalação de fontes desconhecidas).

### Desenvolvedores
```bash
# Clonar o repositório
git clone https://github.com/devairfernandes/ping_master.git

# Entrar na pasta
cd ping_master

# Instalar dependências
flutter pub get

# Rodar o projeto
flutter run
```

---

## 📜 Histórico de Versões
- **v1.0.7:** Sincronização unificada automática e correção de delay com `ping_state.py`.
- **v1.0.6:** Modo Navegador (WebView) e visualização de dashboard dinâmico.
- **v1.0.3:** Adicionada persistência de URL (SharedPreferences).
- **v1.0.2:** Nova logo premium e ajustes finos de UI.
- **v1.0.1:** Implementação completa do sistema de atualização OTA.
- **v1.0.0:** Lançamento inicial com monitoramento e charts.

---

## 👨‍💻 Desenvolvedor
**Devair Fernandes**  
📞 *(69) 99221-4709*  
📍 Brasil

---
*Este projeto é uma ferramenta profissional para infraestrutura de rede.*
