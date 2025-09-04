# Skinia 🔬

**Aplicativo iOS para análise dermatológica de lesões cutâneas usando IA**

Skinia é um aplicativo médico para iPhone que permite fotografar lesões de pele e obter análises automáticas usando tecnologia de inteligência artificial, auxiliando na detecção precoce de condições dermatológicas.

## 📱 Funcionalidades Principais

### ✅ **Já Implementado**
- **📸 Lista de Análises**: Visualização de todas as fotos analisadas
- **🔍 Detalhes da Análise**: Visualização completa dos resultados
- **🎨 Design System Médico**: Interface profissional adaptada para uso clínico
- **♿ Acessibilidade Completa**: Suporte total ao VoiceOver e navegação assistiva
- **📊 Estados de Loading**: Animações elegantes durante processamento
- **🎯 Navegação Robusta**: Sistema de navegação modal otimizado
- **📱 UI/UX Moderna**: Componentes animados e feedback háptico

### 🚧 **Em Desenvolvimento**
- **📷 Captura de Fotos**: Interface de câmera otimizada para dermatologia
- **🤖 Análise IA**: Integração com serviços de machine learning
- **⚙️ Configurações**: Preferências e configurações do usuário
- **🔐 Privacidade**: Gerenciamento de dados e permissões

## 🏗️ Arquitetura Técnica

### **Padrão MVVM-C (Model-View-ViewModel-Coordinator)**
- **Models**: SwiftData para persistência local
- **Views**: SwiftUI com componentes reutilizáveis  
- **ViewModels**: Lógica de negócio e estado das telas
- **Coordinators**: Navegação e fluxo da aplicação

### **Principais Tecnologias**
- **iOS 18.5+** (SwiftUI, SwiftData)
- **Design System** customizado para aplicações médicas
- **Acessibilidade** nativa com VoiceOver
- **Injeção de Dependência** protocol-based
- **Mock System** para desenvolvimento e testes

## 📁 Estrutura do Projeto

```
Skinia/
├── 📁 Models/              # Modelos de dados (SwiftData)
│   ├── SkinLesionPhoto.swift
│   ├── AnalysisResult.swift
│   └── PhotoMetadata.swift
├── 📁 Views/               # Interface do usuário
│   ├── Screens/            # Telas principais
│   ├── Components/         # Componentes reutilizáveis
│   └── Analysis/           # Componentes específicos de análise
├── 📁 ViewModels/          # Lógica de apresentação
├── 📁 Coordinators/        # Navegação e fluxo
├── 📁 Services/            # Serviços e APIs
├── 📁 Utilities/           # Utilitários e helpers
└── 📁 Resources/           # Assets e recursos
```

## 🎨 Design System

### **Paleta de Cores Médica**
- **Primary**: Azul profissional (`#007BA7`)
- **Success**: Verde seguro (`#28A745`) 
- **Warning**: Amarelo atenção (`#FFC107`)
- **Error**: Vermelho urgência (`#DC3545`)
- **Risk Colors**: Escala específica para níveis de risco

### **Componentes Únicos**
- **StatusBadge**: Badges animados para status de análise
- **RiskBadge**: Indicadores visuais de nível de risco
- **LoadingDots**: Animação de carregamento elegante
- **AnalysisListCell**: Células otimizadas para exibição de lesões

## 🔬 Funcionalidades Médicas

### **Estados de Análise**
- `pending` - Aguardando envio
- `uploading` - Enviando para análise
- `analyzing` - Processamento em andamento
- `completed` - Análise concluída
- `failed` - Erro no processamento

### **Níveis de Risco**
- `low` - Risco baixo (verde)
- `moderate` - Risco moderado (amarelo)
- `high` - Risco alto (laranja)  
- `urgent` - Atenção urgente (vermelho)

## 🛠️ Desenvolvimento

### **Requisitos**
- Xcode 15.0+
- iOS 18.5+
- Swift 5.9+

### **Instalação**
```bash
git clone https://github.com/[usuario]/Skinia.git
cd Skinia
open Skinia.xcodeproj
```

### **Build e Teste**
```bash
# Build do projeto
xcodebuild -project Skinia.xcodeproj -scheme Skinia build

# Executar testes
xcodebuild test -project Skinia.xcodeproj -scheme Skinia
```

### **Diretrizes para Claude Code**
- **Não usar simulador**: Apenas builds para verificação
- **Testes pelo usuário**: Screenshots são custosos
- **Usar TodoWrite**: Para gerenciar tarefas complexas
- **Seguir MVVM-C**: Manter arquitetura consistente

## 📋 Status do Projeto

### **Fases Concluídas**
- ✅ **Fase 1**: Fundação e Modelos de Dados
- ✅ **Fase 2**: Interface Principal e Navegação  
- ✅ **Fase 6**: UI/UX Enhancement

### **Próximas Fases**
- 🚧 **Fase 3**: Captura de Fotos e Câmera
- 📋 **Fase 4**: Análise de Fotos (Mock)
- 📋 **Fase 5**: Configurações e Detalhes
- 📋 **Fase 7**: Funcionalidades de Rede

## 👨‍⚕️ Uso Médico

⚠️ **Aviso Importante**: Este aplicativo é destinado para **uso auxiliar** em análises dermatológicas. Os resultados devem sempre ser interpretados por profissionais médicos qualificados. Não substitui consulta médica especializada.

## 🤝 Contribuição

Este projeto segue as melhores práticas de desenvolvimento iOS:

- Código limpo e bem documentado
- SwiftUI + SwiftData como stack principal
- Testes unitários obrigatórios
- Design system consistente
- Acessibilidade em primeiro lugar

## 👥 Equipe

- **Desenvolvedor**: Thales Matheus Mendonça Santos
- **Assistente IA**: Claude Code (Anthropic)

## 📄 Licença

Este projeto está sob licença [MIT](LICENSE).

---

**Desenvolvido com ❤️ para auxiliar profissionais da saúde na detecção precoce de condições dermatológicas**

Para mais informações técnicas detalhadas, consulte o arquivo [CLAUDE.md](CLAUDE.md).