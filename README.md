# Skinia 📱

> Aplicativo iOS para análise inteligente de lesões de pele

Skinia é um aplicativo iOS desenvolvido em SwiftUI que permite aos usuários capturar fotos de lesões de pele e receber análises baseadas em inteligência artificial para auxiliar na detecção precoce de condições dermatológicas, incluindo possíveis casos de câncer de pele.

## 🎯 Funcionalidades Principais

- **📸 Captura de Fotos**: Interface intuitiva para fotografar lesões de pele
- **🤖 Análise por IA**: Upload seguro para servidor remoto com processamento inteligente
- **📊 Resultados Detalhados**: Relatórios com nível de confiança, tipo de lesão e recomendações
- **📝 Histórico**: Lista organizada de todas as análises com status em tempo real
- **🔒 Privacidade**: Dados protegidos e controle total sobre suas informações

## 🏗️ Arquitetura

- **Padrão**: MVVM-C (Model-View-ViewModel-Coordinator)
- **UI Framework**: SwiftUI
- **Persistência**: SwiftData
- **Networking**: URLSession com async/await
- **Testes**: Swift Testing + XCTest

## 📋 Requisitos

- **iOS**: 18.5+
- **Xcode**: 16.4+
- **Swift**: 5.0+
- **Dispositivos**: iPhone e iPad (Universal)

## 🚀 Como Executar

1. Clone o repositório
2. Abra `Skinia.xcodeproj` no Xcode
3. Selecione o target desejado (simulador ou device)
4. Execute o projeto (⌘+R)

## 🧪 Testes

### Testes Unitários
```bash
⌘+U no Xcode ou selecione o scheme SkiniaTests
```

### Testes de UI
```bash
Selecione o scheme SkiniaUITests no Xcode
```

## 📁 Estrutura do Projeto

```
Skinia/
├── Models/              # Modelos de dados SwiftData
├── Views/               # Views SwiftUI
├── ViewModels/          # Lógica de apresentação
├── Coordinators/        # Navegação e fluxo
├── Services/            # Serviços (rede, câmera, etc.)
├── Utilities/           # Utilitários e extensions
├── Resources/           # Assets, cores, strings
└── Tests/              # Testes unitários e UI
```

## 🔄 Estados da Análise

- **🟡 Pendente**: Aguardando envio para o servidor
- **🔄 Enviando**: Upload em progresso
- **⏳ Analisando**: Processamento no servidor
- **✅ Concluída**: Análise finalizada com resultados
- **❌ Falhou**: Erro durante o processo

## 🛡️ Privacidade e Segurança

- Todas as imagens são processadas de forma segura
- Dados sensíveis são protegidos localmente
- Comunicação criptografada com servidor
- Controle total do usuário sobre seus dados

## 📈 Roadmap de Desenvolvimento

O projeto está organizado em 10 fases principais:

1. **Fundação e Modelos** - Base arquitetural e modelos SwiftData
2. **Interface Principal** - Lista de análises e navegação
3. **Captura de Fotos** - Interface de câmera e galeria
4. **Estados Visuais** - Loading, progresso e feedback
5. **Configurações** - Preferências e privacidade
6. **Polimento UI/UX** - Design system e animações
7. **Funcionalidades de Rede** - Upload e API integration
8. **Testes e Qualidade** - Cobertura completa de testes
9. **Otimização** - Performance, segurança e acessibilidade
10. **Produção** - Build final e documentação

## 🤝 Contribuição

Este projeto segue as melhores práticas de desenvolvimento iOS:

- Código limpo e bem documentado
- Testes unitários obrigatórios
- Code review em todas as mudanças
- Semantic versioning
- Conventional commits

## ⚠️ Aviso Médico

**Este aplicativo não substitui consulta médica profissional.** Os resultados fornecidos são apenas para fins informativos e educacionais. Sempre consulte um dermatologista qualificado para diagnóstico e tratamento adequados.

## 📄 Licença

[Definir licença apropriada]

## 👥 Equipe

- **Desenvolvedor**: Thales Matheus Mendonça Santos
- **Organização**: [Definir organização]

---

Para mais informações técnicas detalhadas, consulte o arquivo [CLAUDE.md](CLAUDE.md).