# 🍎 Mac M1 - Setup Mínimo para Controle Remoto via GitHub

## 🎯 **Objetivo**

Instalar o **MÍNIMO** no Mac M1 para permitir **controle total via WSL** usando **GitHub + gh CLI**.

---

## 📋 **Pré-requisitos**

- ✅ Mac M1/M2/M3 (Apple Silicon)
- ✅ macOS 13+ (Ventura ou superior)
- ✅ Conexão com internet
- ✅ Conta GitHub

---

## 🚀 **Instalação no Mac (15-20 minutos)**

### **PASSO 1: Baixar Script de Setup**

No Terminal do Mac:

```bash
# Baixar script
curl -fsSL https://raw.githubusercontent.com/lucasdoreac/hermes-migration/main/mac-m1-minimal-setup.sh -o mac-setup.sh

# Tornar executável
chmod +x mac-setup.sh

# Executar
./mac-setup.sh
```

### **O que o script instala:**

- ✅ **Homebrew** (gerenciador de pacotes)
- ✅ **Python 3.13** (ARM nativo)
- ✅ **Git** (controle de versão)
- ✅ **gh CLI** (GitHub CLI autenticado)
- ✅ **Hermes Agent** (via install.sh oficial)
- ✅ **Estrutura de diretórios** (~/.hermes/, ~/hermes-tasks/)

---

## 🔧 **Configurar Controle Remoto (5 minutos)**

### **No Mac:**

```bash
# Instalar daemon
curl -fsSL https://raw.githubusercontent.com/lucasdoreac/hermes-migration/main/hermes-mac-daemon.sh -o hermes-mac-daemon.sh
chmod +x hermes-mac-daemon.sh

# Executar setup
./hermes-mac-daemon.sh setup

# Iniciar daemon em background
nohup ./hermes-mac-daemon.sh daemon > ~/hermes-logs/daemon.log 2>&1 &

# Verificar se está rodando
ps aux | grep hermes-mac-daemon
```

---

## 🎮 **No WSL - Enviar Comandos para o Mac**

### **PASSO 1: Instalar Script de Controle**

```bash
# No WSL
cd ~/.hermes/scripts
chmod +x hermes-remote-control.sh

# Criar alias
echo 'alias hermes-remote=$HOME/.hermes/scripts/hermes-remote-control.sh' >> ~/.bashrc
source ~/.bashrc
```

### **PASSO 2: Setup do Repositório**

```bash
# No WSL
hermes-remote setup
```

Isso cria o repositório `hermes-mac-tasks` no GitHub.

---

## 📤 **Enviando Comandos do WSL para o Mac**

### **Método 1: Poll (até 60s de latência)**

```bash
# No WSL
hermes-remote send "hermes --version"

# O Mac executará em até 60 segundos
# Verificar status
hermes-remote status

# Ver logs
hermes-remote logs
```

### **Método 2: GitHub Actions (execução instantânea)**

```bash
# No WSL
hermes-remote exec "brew list"

# Acompanhar execução
# Link será impresso
```

---

## 📊 **Arquitetura**

```
┌─────────────────────────────────────────────────────────┐
│                    WSL (Controller)                     │
│                                                           │
│  - hermes-remote-control.sh (envia comandos)            │
│  - gh CLI (interface GitHub)                             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
            ┌─────────────────┐
            │  GitHub         │
            │  - Repositório  │
            │  - Issues       │
            │  - Actions      │
            └────────┬────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                   Mac M1 (Worker)                       │
│                                                           │
│  - hermes-mac-daemon.sh (poll GitHub)                   │
│  - hermes-mac-tasks/ (repositório local)                │
│  - Executa comandos e retorna logs                      │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 **Comandos Disponíveis**

### **No WSL:**

```bash
# Setup
hermes-remote setup

# Enviar comando
hermes-remote send "comando"

# Verificar status
hermes-remote status

# Ver logs
hermes-remote logs

# Execução direta (via Actions)
hermes-remote exec "comando"
```

### **No Mac:**

```bash
# Setup do daemon
./hermes-mac-daemon.sh setup

# Verificar manualmente
./hermes-mac-daemon.sh poll

# Modo daemon (background)
nohup ./hermes-mac-daemon.sh daemon > ~/hermes-logs/daemon.log 2>&1 &
```

---

## ⚙️ **Configurar Auto-Start do Daemon (Mac)**

### **Criar Launch Agent:**

```bash
# No Mac
cat > ~/Library/LaunchAgents/com.hermes.daemon.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.hermes.daemon</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/lucas/hermes-mac-daemon.sh</string>
        <string>daemon</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/lucas/hermes-logs/daemon-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/lucas/hermes-logs/daemon-stderr.log</string>
</dict>
</plist>
EOF

# Carregar serviço
launchctl load ~/Library/LaunchAgents/com.hermes.daemon.plist

# Verificar status
launchctl list | grep hermes
```

---

## 📱 **Monitoramento**

### **No Mac:**

```bash
# Ver logs do daemon
tail -f ~/hermes-logs/daemon.log

# Ver última task executada
ls -lt ~/hermes-logs/task-*.log | head -1

# Ver tasks concluídas
cat ~/hermes-tasks/hermes-mac-tasks/logs/task-*.log
```

### **No WSL:**

```bash
# Ver status remoto
hermes-remote status

# Ver logs remotos
hermes-remote logs
```

---

## 🔐 **Segurança**

### **O que é enviado via GitHub:**
- ✅ Comandos a executar
- ✅ Logs de execução
- ❌ NÃO envia tokens OAuth
- ❌ NÃO envia dados sensíveis

### **Boas práticas:**
- Repositório **privado** (ou público sem dados sensíveis)
- Tokens ficam **no Mac**, não no WSL
- Logs são **apenas output** dos comandos

---

## 🚀 **Próximos Passos**

### **1. Testar Controle Remoto:**

```bash
# No WSL
hermes-remote send "hermes --version"

# Aguardar 60s
hermes-remote status
hermes-remote logs
```

### **2. Instalar MCP Servers no Mac:**

```bash
# No Mac, via WSL
hermes-remote send "hermes mcp install notebooklm-mcp"
hermes-remote send "hermes mcp install zai-vision"
```

### **3. Configurar Workers:**

```bash
# No Mac, adicionar WSL como worker
hermes-remote send "hermes worker add wsl --ssh lucas@192.168.1.x"

# No Mac, adicionar Windows como worker
hermes-remote send "hermes worker add windows --gateway 192.168.1.x:7643"
```

---

## 🎉 **Resultado Final**

**Mac M1 com mínimo instalado:**
- ✅ Python 3.13 (ARM)
- ✅ Hermes Agent
- ✅ GitHub CLI
- ✅ Daemon de controle remoto

**WSL como Controller:**
- ✅ Envia comandos via GitHub
- ✅ Recebe logs de execução
- ✅ Controle total do Mac

---

## 📚 **Referências**

- GitHub CLI: https://cli.github.com/
- Hermes Agent: https://hermes-agent.nousresearch.com/
- Homebrew: https://brew.sh/

---

**Última atualização:** 2026-05-24  
**Versão:** 1.0.0  
**Status:** ✅ Pronto para Implementação
