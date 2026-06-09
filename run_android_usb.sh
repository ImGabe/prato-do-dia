#!/usr/bin/env bash

# Script de Automação de Setup e Execução do Flutter via USB no Fedora
# Prato do Dia

# Configuração de Cores para output premium
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sem cor

echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}      Prato do Dia - Assistente de Inicialização USB (Fedora)   ${NC}"
echo -e "${BLUE}================================================================${NC}"

# 1. Verificar e instalar ferramentas necessárias (ADB) no Fedora
if ! command -v adb &> /dev/null; then
    echo -e "${YELLOW}[!] 'adb' não foi encontrado no seu sistema.${NC}"
    echo -e "${BLUE}[*] Instalando 'android-tools' via DNF (requer privilégios de sudo)...${NC}"
    
    if sudo dnf install -y android-tools; then
        echo -e "${GREEN}[✓] Ferramentas do Android instaladas com sucesso!${NC}"
    else
        echo -e "${RED}[✗] Falha ao instalar as dependências. Instale manualmente usando: sudo dnf install android-tools${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}[✓] ADB (Android Debug Bridge) detectado no sistema.${NC}"
fi

# 2. Iniciar o servidor ADB
echo -e "${BLUE}[*] Inicializando o servidor ADB...${NC}"
adb start-server &> /dev/null

# 3. Aguardar o dispositivo móvel ser conectado via USB
echo -e "${YELLOW}[!] Por favor, conecte o celular Android via cabo USB com a 'Depuração USB' ativada.${NC}"
echo -e "${BLUE}[*] Aguardando conexão de dispositivo(s)...${NC}"

while true; do
    # Verifica dispositivos conectados e autorizados
    mapfile -t devices_array < <(adb devices | grep -v "List of devices" | grep "device$")
    unauthorized_list=$(adb devices | grep -v "List of devices" | grep "unauthorized$")
    
    if [ ! -z "$unauthorized_list" ]; then
        echo -e "${RED}[⚠️] Dispositivo detectado mas NÃO autorizado! Verifique a tela do seu celular e autorize a depuração.${NC}"
    fi
    
    num_devices=${#devices_array[@]}
    
    if [ "$num_devices" -gt 0 ]; then
        if [ "$num_devices" -eq 1 ]; then
            device_line="${devices_array[0]}"
            device_name=$(echo "$device_line" | awk '{print $1}')
            echo -e "${GREEN}[✓] Único dispositivo conectado e pronto: $device_name${NC}"
            break
        else
            echo -e "${YELLOW}[!] Múltiplos dispositivos conectados detectados:${NC}"
            for i in "${!devices_array[@]}"; do
                d_name=$(echo "${devices_array[$i]}" | awk '{print $1}')
                echo -e "  [$((i+1))] $d_name"
            done
            
            while true; do
                read -r -p "Escolha o número do dispositivo para rodar (1-$num_devices): " choice
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$num_devices" ]; then
                    selected_index=$((choice - 1))
                    device_name=$(echo "${devices_array[$selected_index]}" | awk '{print $1}')
                    echo -e "${GREEN}[✓] Dispositivo selecionado: $device_name${NC}"
                    break 2
                else
                    echo -e "${RED}[✗] Escolha inválida. Tente novamente.${NC}"
                fi
            done
        fi
    fi
    sleep 2
done

# 4. Configurar redirecionamento de porta (ADB Reverse)
echo -e "${BLUE}[*] Configurando redirecionamento da porta 42917 (computador -> celular)...${NC}"
if adb -s "$device_name" reverse tcp:42917 tcp:42917; then
    echo -e "${GREEN}[✓] ADB Reverse configurado com sucesso!${NC}"
    echo -e "${GREEN}    O app no celular poderá se conectar à API em http://localhost:42917${NC}"
else
    echo -e "${RED}[✗] Falha ao configurar o redirecionamento de porta.${NC}"
fi

# 5. Verificar se a API backend está rodando localmente
echo -e "${BLUE}[*] Verificando se a API backend está ativa localmente na porta 42917...${NC}"
# Tenta fazer uma requisição rápida para a rota de health
if curl -s -m 2 http://localhost:42917/health &> /dev/null; then
    echo -e "${GREEN}[✓] API Backend detectada e ativa!${NC}"
else
    echo -e "${YELLOW}[⚠️] Alerta: Não detectamos a API ativa na porta 42917.${NC}"
    echo -e "${YELLOW}    Lembre-se de rodar o servidor no terminal da API usando:${NC}"
    echo -e "${YELLOW}    uv run uvicorn prato_do_dia_api.main:app --host 0.0.0.0 --port 42917 --reload${NC}"
fi

# 6. Rodar o Flutter no Dispositivo Conectado
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/pubspec.yaml" ]; then
    MOBILE_DIR="$SCRIPT_DIR"
else
    MOBILE_DIR="$SCRIPT_DIR/prato-do-dia-mobile"
fi

if [ -d "$MOBILE_DIR" ]; then
    echo -e "${BLUE}[*] Acessando diretório do projeto mobile: $(basename "$MOBILE_DIR")${NC}"
    cd "$MOBILE_DIR" || exit
    
    echo -e "${BLUE}[*] Compilando e executando o app no seu dispositivo...${NC}"
    echo -e "${GREEN}    (Pressione 'r' no terminal para Hot Reload após inicializar)${NC}"
    flutter run -d "$device_name"
else
    echo -e "${RED}[✗] Erro: Não foi possível localizar a pasta do projeto mobile em $MOBILE_DIR${NC}"
    exit 1
fi
