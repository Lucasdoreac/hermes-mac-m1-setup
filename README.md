# 🏗️ Hermes Multi-Machine — Arquitetura 3.0

> **Última atualização:** 25 de Maio de 2026
> **Status:** ✅ Infra SSH completa e testada

---

## 📐 Arquitetura

```
  TELEGRAM (App)
      │
      ▼
┌─────────────────────────────────┐
│   🍎 Mac M1 — CONTROLLER       │
│   Gateway Telegram + WhatsApp   │
│   Hermes v0.14.0                │
│   Orquestra tarefas via SSH     │
└──────┬──────────────┬───────────┘
       │ SSH          │ SSH
       ▼              ▼
┌──────────────┐ ┌───────────────┐
│ 🐧 WSL       │ │ 🪟 Windows    │
│ Worker Linux │ │ Worker Win    │
│ Hermes v0.14 │ │ OpenSSH Srv   │
│ IP: via Win  │ │ IP: 192.168.  │
│              │ │      0.12     │
└──────────────┘ └───────────────┘
```

**Princípio:** Um único gateway (Mac), workers acessíveis via SSH.
Sem bot-bot communication. Sem gateway duplicado.

---

## ✅ Status Atual

### Mac M1 (Controller)
- ✅ Hermes v0.14.0
- ✅ SSH key gerada (ed25519)
- ✅ SSH para WSL testado e funcionando
- ✅ Telegram bot configurado
- ✅ Gateway rodando

### WSL (Worker Linux)
- ✅ Hermes v0.14.0 instalado (este é o bot "her" no Telegram)
- ✅ SSH server rodando (porta 22)
- ✅ SSH key do Mac autorizada
- ✅ Port Proxy Windows (0.0.0.0:22 → 172.22.140.182:22)
- ✅ Firewall Windows regra SSH ativa
- ✅ Gateway ATIVO (aguardando definição se desativa)
- ❌ Docker NÃO instalado (opcional)

### Windows (Worker)
- ✅ IP Wi-Fi: 192.168.0.12
- ❌ OpenSSH Server precisa habilitar
- ❌ Docker NÃO instalado

---

## 🔗 Como Acessar Workers do Mac

### WSL (via Windows port proxy)
```bash
ssh lucas@192.168.0.12 "comando"
```
O Windows redireciona porta 22 → WSL 172.22.140.182:22

### Windows (quando OpenSSH habilitado)
```bash
ssh Lucas@192.168.0.12 "powershell comando"
```

---

## 📁 Arquivos deste Repo

| Arquivo | Descrição |
|---------|-----------|
| `README.md` | Este arquivo — visão geral |
| `INFRA_SETUP_COMPLETO.md` | Guia completo de configuração SSH |
| `ARCHIVE/` | Guias antigos da versão 2.0 |

---

## 📋 Checklist

### Mac (Controller)
- [x] Hermes instalado
- [x] Telegram bot configurado
- [x] Gateway rodando
- [x] SSH keys configuradas
- [x] Conexão WSL testada

### WSL (Worker)
- [x] Hermes instalado
- [x] SSH server rodando
- [x] SSH key do Mac autorizada
- [x] Port proxy configurado
- [x] Firewall regra SSH
- [ ] Gateway desativado (decidir)
- [ ] Docker (opcional)

### Windows (Worker)
- [ ] OpenSSH Server habilitado
- [ ] Docker (opcional)

---

## ⚠️ Notas Importantes

- **NÃO limpar "bloat" do Mac** — HuggingFace, UV cache, npm são necessários
- **Docker é opcional** — só necessário para sandboxing de comandos arriscados
- **O WSL TEM Hermes instalado** — é o bot "her" no Telegram
- **Rede WSL = modo NAT** — acesso via port proxy do Windows

---

## 📚 Referências

- Hermes Agent: https://hermes-agent.nousresearch.com/
- NotebookLM caderno: `c85a9243-3eac-444c-2afaad8f0f93`

**Licença:** MIT | **Autor:** Lucasdoreac
