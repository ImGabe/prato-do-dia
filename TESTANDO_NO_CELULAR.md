# Como Testar o Aplicativo no Celular Real

Este guia descreve o passo a passo para compilar, executar e testar o aplicativo **Prato do Dia** em um dispositivo móvel físico (Android ou iOS) conectado à API de desenvolvimento local que está rodando no seu computador.

---

## 📋 Pré-requisitos Básicos

1. **Flutter SDK:** Certifique-se de que o Flutter está configurado no seu computador executando `flutter doctor`.
2. **Dispositivo Físico:** Um celular Android ou iOS conectado ao computador por cabo USB.

---

## 🛠️ Configuração do Dispositivo

### Para Dispositivos Android (Recomendado/Mais Simples)
1. No seu celular, vá em **Configurações** > **Sobre o telefone**.
2. Toque no **Número da versão** (ou *Build Number*) **7 vezes** seguidas para ativar as **Opções do Desenvolvedor**.
3. Volte ao menu anterior, acesse **Opções do Desenvolvedor** e ative a opção **Depuração USB**.
4. Conecte o celular ao computador via cabo USB. Se aparecer uma janela no celular perguntando se confia no computador, aceite/autorize.

### Para Dispositivos iOS
1. Conecte o celular ao computador macOS por cabo e clique em **Confiar neste computador** no celular.
2. Certifique-se de ter o **Xcode** instalado.
3. No iOS 16 ou superior, vá em **Ajustes** > **Privacidade e Segurança** > ative o **Modo de Desenvolvedor** e reinicie o aparelho se solicitado.
4. É necessário configurar um time de desenvolvimento (*Personal Team*) no Xcode abrindo a pasta `ios/Runner.xcworkspace`.

---

## 🔌 Conectando o Celular à API Local (Importante!)

Como o servidor backend da API roda na sua máquina de desenvolvimento local (porta `42917`), precisamos garantir que o aplicativo rodando no celular consiga alcançá-lo. Escolha **um** dos dois métodos abaixo:

### Método A: Redirecionamento de Porta USB (Somente Android - Recomendado)

Este método é o mais robusto pois **não depende de rede Wi-Fi** e funciona enviando o tráfego do celular diretamente pela conexão USB do cabo.

1. Abra um terminal no seu computador e execute:
   ```bash
   adb reverse tcp:42917 tcp:42917
   ```
   *(Isso faz com que qualquer requisição que o celular faça para `localhost:42917` seja redirecionada automaticamente para a porta `42917` do seu computador).*
2. Abra o aplicativo **Prato do Dia** no celular.
3. Toque no **ícone de engrenagem** (Configurações) no canto superior direito da tela inicial do app.
4. Digite exatamente: `http://localhost:42917` e clique em **Salvar**.
5. **Pronto!** O app já está integrado com o seu backend local.

---

### Método B: Conexão via Rede Wi-Fi Local (Android e iOS)

Use este método se estiver testando no iOS ou preferir testar sem depender do cabo USB após a inicialização.

1. **Mesma Rede:** Garanta que tanto o computador quanto o celular estejam conectados **na mesma rede Wi-Fi**.
2. **Obtenha o IP Local do seu Computador:**
   * No **Linux/macOS**, execute: `ip route` ou `ifconfig` (procure por algo como `192.168.1.XX` ou `10.0.0.XX`).
   * No **Windows**, abra o prompt de comando e execute: `ipconfig`.
3. **Inicie o Backend da API escutando na rede local:**
   Certifique-se de que a API foi iniciada vinculada a todas as interfaces (`0.0.0.0`), executando:
   ```bash
   uv run uvicorn prato_do_dia_api.main:app --host 0.0.0.0 --port 42917 --reload
   ```
4. Abra o aplicativo **Prato do Dia** no celular.
5. Toque no **ícone de engrenagem** (Configurações) no canto superior direito do app.
6. Configure a URL da API substituindo o IP local pelo IP do seu computador obtido no Passo 2:
   * Exemplo: `http://192.168.1.150:42917`
7. Clique em **Salvar**.

> [!WARNING]
> Se o aplicativo apresentar erro de timeout ou não conectar utilizando o Wi-Fi local, verifique se o **Firewall** do seu computador não está bloqueando conexões de entrada na porta `42917`.

---

## 🚀 Compilando e Executando o Aplicativo

Com o celular conectado e configurado:

1. No terminal do computador, acesse a pasta do projeto mobile:
   ```bash
   cd prato-do-dia-mobile
   ```
2. Liste os dispositivos conectados para verificar se o seu aparelho é reconhecido:
   ```bash
   flutter devices
   ```
3. Execute o comando para compilar e iniciar o aplicativo em modo de depuração (*Debug Mode*):
   ```bash
   flutter run
   ```
   *(Se houver mais de um dispositivo disponível, use `flutter run -d <ID_DO_DISPOSITIVO>` passando o ID do seu aparelho mostrado na listagem).*

---

## 🔍 Resolução de Problemas (Troubleshooting)

* **Erro de Permissão de Câmera:**
  * O aplicativo solicita acesso à câmera na inicialização da tela de captura. Caso tenha recusado por engano, vá nas configurações do sistema do seu celular, encontre o app **Prato do Dia** e ative a permissão de Câmera manualmente.
* **Tempo Limite de Conexão (Timeout de 15s):**
  * Se receber um alerta informando que a conexão expirou, verifique se a API local está ligada e se digitou a URL/porta correta na engrenagem de configurações do app.
  * Se estiver usando o **Método A (USB)**, verifique se o comando `adb reverse` não foi interrompido (ele precisa ser reexecutado caso você desconecte e reconecte o cabo USB).
