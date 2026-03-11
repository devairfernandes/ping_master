# <img src="assets/logo.png" width="40" height="40" /> Ping Master - Ouromax

![Version](https://img.shields.io/badge/version-1.0.4-00E676?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

O **Ping Master** é um painel de monitoramento de rede de alta performance desenvolvido para técnicos e administradores que precisam de precisão em tempo real. Inspirado no ecossistema **Ouromax**, o app combina uma estética *Pure Black* premium com ferramentas robustas de análise de estabilidade.

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

| Tela de Entrada | Dashboard Principal |
| :---: | :---: |
| <img src="https://raw.githubusercontent.com/devairfernandes/ping_master/main/assets/logo.png" width="200" /> | *(Placeholder para Screenshot)* |

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
- **v1.0.4:** Modo Offline (Demo) e melhorias de Timeout.
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
*Este projeto é parte da suíte de ferramentas Ouromax para infraestrutura de rede.*
