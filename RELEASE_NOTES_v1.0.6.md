# Ping Master v1.0.6 (Release Notes)

🎉 **Nova Abordagem: Modo Navegador**

Atendendo às necessidades de flexibilidade, agora o Ping Master pode funcionar como um navegador dedicado para o seu painel de monitoramento.

### 🚀 Novidades desta versão:
- **Modo Navegador (WebView):** Ao invés de apenas tentar ler dados técnicos (JSON), o app agora carrega a página HTML completa do seu servidor. Isso resolve problemas de compatibilidade com servidores que não possuem uma API JSON padrão.
- **Suporte a URLs Dinâmicas:** Você pode colocar qualquer IP ou link (ex: `google.com`) e o app carregará como um dashboard.
- **Alternância de Visualização:** Adicionamos um ícone no topo para você alternar entre o **Dashboard Nativo** (com gráficos) e o **Modo Navegador** a qualquer momento.
- **Normalização Automática:** O app detecta se você esqueceu do `http://` e corrige automaticamente.

### 🛠 Melhorias:
- Base construída com `webview_flutter` para máxima performance de renderização web.
- Indicador de carregamento integrado.

---
*Ping Master - Potencializando seu monitoramento.*
