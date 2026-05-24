# 🐧 WSL - Worker Linux - Instruções Completas

## 🎯 **OBJETIVO**

Configurar o WSL como **Worker Linux** do ecossistema Hermes, recebendo comandos do Mac Controller.

---

## 📊 **MUDANÇA ESTRATÉGICA:**

**ANTES (Errado):**
```
WSL = Controller (roda gateway, Telegram)
```

**DEPOIS (Correto):**
```
Mac = Controller (roda gateway, Telegram, orquestra)
WSL = Worker (executa tarefas Linux específicas)
```

**Por que?**
- ✅ Mac M1 é 150% mais rápido em Python
- ✅ Mac é mais estável para rodar 24/7
- ✅ WSL deve focar em tarefas Linux específicas
- ✅ Evita conflitos de Telegram/gateway

---

## 📋 **SITUAÇÃO ATUAL DO WSL:**

```bash
# WSL:
✅ Hermes v0.14.0 rodando
✅ Bot Telegram ATIVO (precisa DESATIVAR)
✅ Gateway rodando (precisa PARAR)
✅ Provider: Z.AI GLM configurado
❌ Precisa configurar para receber comandos do Mac
```

---

## 🚀 **INSTRUÇÕES PASSO A PASSO:**

### **PASSO 1: VERIFICAR HERMES**

```bash
# No WSL, execute:
hermes --version

# Deve mostrar: Hermes Agent v0.14.0 (ou similar)
```

---

### **PASSO 2: PARAR GATEWAY HERMES**

**CRITICAL:** O WSL NÃO pode mais rodar o gateway!

```bash
# Matar gateway se estiver rodando
pkill -f "hermes.*gateway"

# OU via Hermes
hermes gateway stop

# Verificar se parou
ps aux | grep -i "hermes.*gateway"

# Não deve mostrar nada
```

---

### **PASSO 3: DESATIVAR GATEWAY NO CONFIG**

```bash
# Editar config
nano ~/.hermes/config.yaml

# Garantir que exista:
telegram:
  telegram: []  # ❌ VAZIO = Bot desativado

gateway:
  enabled: false  # ❌ Gateway desativado

# Salvar: Ctrl+O, Enter, Ctrl+X
```

**OU via comando:**

```bash
# Adicionar ao config
echo "
telegram:
  telegram: []

gateway:
  enabled: false
" >> ~/.hermes/config.yaml
```

---

### **PASSO 4: VERIFICAR CONFIG**

```bash
# Verificar configuração
cat ~/.hermes/config.yaml | grep -A 5 "telegram\|gateway"

# Deve mostrar:
telegram:
  telegram: []

gateway:
  enabled: false
```

---

### **PASSO 5: MANTER PROVIDER CONFIGURADO**

```bash
# O WSL PRECISA de provider para executar tarefas localmente!

# Verificar provider
hermes model

# Deve mostrar:
# Provider: custom
# Base URL: https://api.z.ai/api/anthropic
# API Key: 42bdb72c211a4db8b47d8ee1ab675f50.ilmviufQAJrq3FLc

# Se não estiver configurado, configurar:
hermes model

# Escolha:
# - Provider: custom
# - Base URL: https://api.z.ai/api/anthropic
# - API Key: 42bdb72c211a4db8b47d8ee1ab675f50.ilmviufQAJrq3FLc
```

---

### **PASSO 6: TESTAR HERMES LOCALMENTE**

```bash
# Testar Hermes localmente
hermes chat "Qual sua versão?"

# Deve responder com info do Hermes

# Testar cálculo
hermes chat "Quanto é 2 + 2?"

# Deve responder "4" ou similar
```

---

### **PASSO 7: CONFIGURAR SSH SERVER**

**CRITICAL:** Para receber comandos do Mac!

```bash
# Instalar SSH server (se não tiver)
sudo apt update
sudo apt install -y openssh-server

# Iniciar SSH server
sudo service ssh start

# Habilitar SSH no boot
sudo systemctl enable ssh

# Verificar status
sudo service ssh status

# Deve mostrar: "active (running)"
```

---

### **PASSO 8: CONFIGURAR SSH KEY**

```bash
# No WSL, gerar SSH key (se não tiver)
ssh-keygen -t rsa -b 4096 -C "lucas@wsl"

# Copiar key para Mac
cat ~/.ssh/id_rsa.pub

# No Mac, adicionar a key
# (execute no Mac)
ssh-copy-id lucas@IP_DO_WSL

# Testar SSH do Mac
# (execute no Mac)
ssh lucas@IP_DO_WSL

# Deve conectar sem senha
```

---

### **PASSO 9: DESCOBRIR IP DO WSL**

```bash
# Descobrir IP do WSL
ip addr show eth0 | grep inet

# OU
hostname -I

# Anote o IP (ex: 172.25.144.1)
```

---

### **PASSO 10: CRIAR SCRIPT DE CONTROLE REMOTO**

```bash
# Criar script para receber comandos do Mac
cat > ~/.hermes/scripts/worker-receive.sh << 'EOF'
#!/bin/bash
# Script para receber comandos do Mac Controller

LOG_DIR="$HOME/.hermes/logs"
COMMAND_FILE="$LOG_DIR/command.txt"
RESULT_FILE="$LOG_DIR/result.txt"

mkdir -p "$LOG_DIR"

# Loop infinito
while true; do
  # Verificar se existe comando
  if [ -f "$COMMAND_FILE" ]; then
    # Ler comando
    COMMAND=$(cat "$COMMAND_FILE")

    # Executar comando
    cd "$HOME/.hermes"
    eval "$COMMAND" > "$RESULT_FILE" 2>&1

    # Remover comando
    rm "$COMMAND_FILE"

    # Notificar (opcional)
    echo "Comando executado: $COMMAND"
  fi

  # Aguardar 5 segundos
  sleep 5
done
EOF

chmod +x ~/.hermes/scripts/worker-receive.sh
```

---

### **PASSO 11: CONFIGURAR SYSTEMD TIMER (AUTO-START)**

```bash
# Criar serviço systemd
cat > ~/.config/systemd/user/hermes-worker.service << 'EOF'
[Unit]
Description=Hermes Worker Service
After=network.target

[Service]
Type=simple
ExecStart=%h/.hermes/scripts/worker-receive.sh
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

# Habilitar serviço
systemctl --user daemon-reload
systemctl --user enable hermes-worker.service
systemctl --user start hermes-worker.service

# Verificar status
systemctl --user status hermes-worker.service
```

---

### **PASSO 12: TESTAR COMUNICAÇÃO MAC → WSL**

```bash
# No Mac, enviar comando ao WSL:
ssh lucas@IP_DO_WSL "cd ~/.hermes && hermes chat 'Olá WSL!'"

# Deve executar no WSL e retornar resultado
```

---

### **PASSO 13: CONFIGURAR CRON JOBS (SE NECESSÁRIO)**

```bash
# Editar crontab
crontab -e

# Adicionar jobs (exemplo)
# Executar script de backup diariamente às 2h
0 2 * * * /home/lucas/.hermes/scripts/backup.sh >> /home/lucas/.hermes/logs/backup.log 2>&1

# Executar script de sync a cada hora
0 * * * * /home/lucas/.hermes/scripts/sync.sh >> /home/lucas/.hermes/logs/sync.log 2>&1

# Salvar
```

---

### **PASSO 14: MANTER MCP SERVERS ATIVOS**

```bash
# O WSL pode manter MCP servers ativos para uso local

# Verificar MCP servers
hermes mcp list

# Deve mostrar:
# - zai-vision (npx)
# - web-search-prime (HTTP)
# - web-reader (HTTP)
# - zread (HTTP)
# - notebooklm-mcp (stdio)
```

---

### **PASSO 15: CONFIGURAR GOOGLE WORKSPACE (OPCIONAL)**

```bash
# O WSL pode ter Google Workspace separado
# OU pode usar o mesmo token do Mac (via compartilhamento de rede)

# Instalar gws CLI
pipx install gws-cli

# Configurar
gws auth login

# Isso abrirá navegador para OAuth Google

# Verificar
gws calendar list
gws gmail list
```

---

## ✅ **RESULTADO ESPERADO:**

Após seguir todos os passos, o WSL deve:

```
✅ Hermes configurado com provider (Z.AI)
✅ Gateway DESATIVADO (não processa Telegram)
✅ Bot DESATIVADO (não tenta ler mensagens)
✅ SSH server configurado (recebe comandos do Mac)
✅ Worker script rodando (systemd service)
✅ Pronto para receber comandos do Mac
✅ MCP servers ativos (uso local)
```

---

## 🎮 **COMO USAR:**

### **Do Mac (Controller):**

```bash
# Enviar comando ao WSL
ssh lucas@IP_DO_WSL "cd ~/.hermes && hermes chat 'Execute tarefa X'"

# Enviar script para executar
scp ~/script.sh lucas@IP_DO_WSL:/tmp/
ssh lucas@IP_DO_WSL "bash /tmp/script.sh"

# Ver status do WSL
ssh lucas@IP_DO_WSL "systemctl --user status hermes-worker.service"
```

### **No WSL (Worker):**

```bash
# Executar tarefas localmente
hermes chat "Processar dados"

# Ver logs
tail -f ~/.hermes/logs/worker.log

# Ver status
systemctl --user status hermes-worker.service
```

---

## 🚨 **TROUBLESHOOTING:**

### **Erro: "Connection refused"**

```bash
# Verificar se SSH server está rodando
sudo service ssh status

# Se não estiver, iniciar
sudo service ssh start

# Habilitar no boot
sudo systemctl enable ssh
```

### **Erro: "Permission denied"**

```bash
# Configurar SSH key corretamente
ssh-copy-id lucas@IP_DO_WSL

# Testar
ssh lucas@IP_DO_WSL
```

### **Worker não inicia:**

```bash
# Verificar logs
journalctl --user -u hermes-worker.service -f

# Tentar manualmente
bash ~/.hermes/scripts/worker-receive.sh
```

### **Gateway ainda tenta iniciar:**

```bash
# Verificar config
cat ~/.hermes/config.yaml | grep -A 5 "gateway\|telegram"

# Deve mostrar:
# gateway:
#   enabled: false
# telegram:
#   telegram: []

# Se não, editar
nano ~/.hermes/config.yaml
```

---

## 📚 **REFERÊNCIAS:**

- **Hermes Agent:** https://hermes-agent.nousresearch.com/
- **SSH Server:** https://ubuntu.com/server/docs/service-openssh
- **Systemd User Services:** https://www.freedesktop.org/software/systemd/man/systemd.user.html

---

## 🎯 **RESUMO RÁPIDO:**

```bash
# 1. Parar gateway
pkill -f "hermes.*gateway"

# 2. Desativar gateway
echo "
telegram:
  telegram: []
gateway:
  enabled: false
" >> ~/.hermes/config.yaml

# 3. Configurar SSH
sudo apt install -y openssh-server
sudo service ssh start
sudo systemctl enable ssh

# 4. Criar worker script
mkdir -p ~/.hermes/scripts
cat > ~/.hermes/scripts/worker-receive.sh << 'EOF'
#!/bin/bash
# (script do PASSO 10)
EOF
chmod +x ~/.hermes/scripts/worker-receive.sh

# 5. Configurar systemd
systemctl --user enable hermes-worker.service
systemctl --user start hermes-worker.service

# 6. Testar
hermes chat "Teste local"
```

---

**Última atualização:** 2026-05-24  
**Versão:** 3.0.0 (Worker Linux)  
**Status:** ✅ Pronto para Implementação

---

## 💡 **NOTA IMPORTANTE:**

O WSL agora é um **Worker Linux**:
- ❌ NÃO compete com o Mac pelo Telegram
- ❌ NÃO roda gateway
- ❌ NÃO processa mensagens do Telegram
- ✅ Executa tarefas Linux específicas
- ✅ Recebe comandos do Mac via SSH
- ✅ Mantém provider para uso local
- ✅ Pode ter MCP servers ativos

**Isso MUDA a arquitetura anterior e MELHORA a performance geral!** 🚀
