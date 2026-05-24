# 🔧 Infra Setup Completo — Hermes Multi-Machine

> Guia passo-a-passo **já executado e validado** em 25/Maio/2026

---

## 1. WSL — Instalar SSH Server

```bash
sudo apt-get update && sudo apt-get install -y openssh-server
```

**Configurar e iniciar:**
```bash
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl enable ssh
sudo systemctl start ssh
```

**Verificar:**
```bash
sudo systemctl status ssh
# → active (running)
```

---

## 2. WSL — Gerar SSH Key (worker)

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "lucas@wsl-worker" -f ~/.ssh/id_ed25519 -N ""
```

---

## 3. WSL — Autorizar Key do Mac

```bash
# Cole a public key do Mac Controller:
echo 'ssh-ed25519 AAAAC3... lucasdorea.c@gmail.com' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

---

## 4. Windows — Firewall + Port Proxy

**No PowerShell como Administrador:**

```powershell
# Regra de firewall para SSH
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' `
  -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

# Port proxy: Windows IP → WSL
netsh interface portproxy add v4tov4 `
  listenport=22 listenaddress=0.0.0.0 `
  connectport=22 connectaddress=172.22.140.182
```

**Verificar:**
```powershell
Get-NetFirewallRule -Name sshd | Format-List DisplayName,Enabled,Action
netsh interface portproxy show v4tov4
```

---

## 5. Mac — Gerar SSH Key (controller)

```bash
[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -C "lucas@mac-controller"
cat ~/.ssh/id_ed25519.pub
# Copiar a saída e adicionar no WSL (Passo 3)
```

---

## 6. Testar Conexão

**No Mac:**
```bash
ssh lucas@192.168.0.12 "echo 'Mac → WSL OK!' && hostname"
# → Mac → WSL OK!
# → wind-olws
```

---

## 📊 Dados da Rede

| Componente | IP | Porta | Nota |
|---|---|---|---|
| Windows Wi-Fi | 192.168.0.12 | 22 | Port proxy → WSL |
| WSL interno | 172.22.140.182 | 22 | SSH server |
| WSL gateway | NAT | — | localhostForwarding=true |

---

## 🪟 Windows — Habilitar OpenSSH (futuro)

```powershell
# PowerShell como Administrador
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
```

---

## ⚠️ Troubleshooting

**"Connection refused":**
- Verificar SSH server: `sudo systemctl status ssh`
- Verificar port proxy: `netsh interface portproxy show v4tov4`
- Verificar firewall: `Get-NetFirewallRule -Name sshd`

**"Permission denied":**
- Verificar authorized_keys: `cat ~/.ssh/authorized_keys`
- Permissões: `chmod 600 ~/.ssh/authorized_keys`
- Key do Mac está correta no arquivo?

**WSL reinicia e perde SSH:**
- `sudo systemctl enable ssh` garante auto-start
- WSL com systemd=true no /etc/wsl.conf
