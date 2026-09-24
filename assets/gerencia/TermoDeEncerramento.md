# Termo de Encerramento do Projeto: PetTrail

**Componentes da Equipe:**
- Bernardo de Resende Marcelino
- Flávio de Souza Júnior
- João Marcelo Carvalho Pereira Araújo
- Luidi Cadete Silva
- Miguel Figueiredo Diniz

---

### 1. Objetivo do projeto
Desenvolver o PetTrail, uma plataforma digital de passeio de pets que conecta donos de animais de estimação a passeadores autônomos. O sistema permitirá que donos localizem passeadores disponíveis em tempo real por meio de um mapa, solicitem passeios imediatos, acompanhem o trajeto do pet com rastreamento GPS e recebam um relatório automático ao final de cada passeio. O objetivo é transformar um serviço atualmente informal e sem rastreabilidade em uma experiência segura, transparente e documentada para ambos os lados.

### 2. Resumo do projeto
O projeto PetTrail consistiu no desenvolvimento de uma solução distribuída e robusta para suprir a falta de transparência no mercado informal de passeios de animais de estimação. A solução desenvolvida integra múltiplos componentes de software projetados para operar em harmonia e tempo real: um aplicativo móvel cross-platform para tutores e passeadores, um portal administrativo e de acompanhamento via ambiente web, uma API central para orquestração das regras de negócio e autenticação, e um microsserviço dedicado ao processamento assíncrono em segundo plano.

As atividades desenvolvidas ao longo do projeto seguiram as fases delimitadas pelo planejamento e pela Estrutura Analítica do Projeto (EAP), abrangendo:
1. **Iniciação e Gerenciamento:** Formulação das diretrizes de escopo, prazos, estimativas de custos no Termo de Abertura do Projeto (TAP) e alinhamento inicial na reunião de kickoff.
2. **Modelagem e Design de Interface:** Concepção da experiência do usuário através da criação de wireframes detalhados (mobile e web) e validação dos padrões de usabilidade por meio de uma documentação completa de avaliação heurística.
3. **Desenvolvimento de Infraestrutura e Banco de Dados:** Modelagem relacional no PostgreSQL e provisionamento de mensageria assíncrona orientada a eventos para desacoplamento de carga.
4. **Implementação de Software (Backend, Frontend e Mobile):** Codificação da APIREST, sincronização em tempo real via canais WebSocket, desenvolvimento da captura de posicionamento em segundo plano e construção de dashboards analíticos responsivos.
5. **Implantação (Deploy) e Testes:** Configuração de esteiras de entrega contínua em ambientes de nuvem pública e preparação dos pacotes nativos para publicação nas lojas virtuais de aplicativos.

### 3. Artefatos entregues
Os artefatos produzidos e entregues foram organizados estruturalmente para sanar de ponta a ponta o problema de segurança e informalidade do serviço de passeio:

* **Artefatos de Gestão, Governança e Legal:**
    * **Termo de Abertura do Projeto (TAP) e EAP:** Documentos formais especificando as fronteiras de escopo (com inclusão do rastreamento em tempo real e exclusão de pagamentos internos), cronograma estimado em 100 horas de dedicação e orçamento para operação das contas de serviços de nuvem.
    * **Atas de Alinhamento e Acordos Formais:** Atas de reuniões de alinhamento presencial em sala e atas de contribuição individual segmentadas por Sprints (Sprint 2 e Sprint 3), garantindo a rastreabilidade das tomadas de decisão da equipe, além do Termo de Sigilo e Confidencialidade e Ata de Acordo sem Parceiro Externo.
* **Artefatos de Design e Experiência do Usuário (UX/UI):**
    * **Projeto de Interfaces (Figma):** Composto por 12 telas dedicadas ao fluxo móvel (abrangendo telas de login, busca de passeadores por mapa de calor, tela de progresso do trajeto ativo com desenho dinâmico da trilha e telas de avaliação mútua) e 11 telas para a interface web desktop (com visões consolidadas do tutor e do passeador).
    * **Documento de Avaliação Heurística:** Relatório de análise de usabilidade aplicada sobre os protótipos para mitigar erros de navegação e garantir acessibilidade a usuários leigos.
* **Artefatos de Engenharia de Software e Solução Tecnológica:**
    * **Aplicativo Mobile Funcional (Flutter):** Executável nativo para Android e iOS que atua como interface operacional de campo. Incorpora os plugins de geolocalização contínua para disparar coordenadas a cada 5 segundos e componentes de leitura/validação presencial por código numérico de 6 dígitos e QR Code para autenticação física do início e término do passeio.
    * **Backend Unificado (NestJS):** API central construída sob arquitetura modular contendo controle de acesso baseado em papéis (RBAC) via tokens JWT, persistência estruturada por meio do TypeORM conectando ao PostgreSQL e um gateway WebSocket configurado para sustentar conexões persistentes simultâneas sem perda de pacotes GPS.
    * **Microserviço de Relatórios (Node.js):** Um *worker* assíncrono isolado que consome mensagens de uma fila e efetua processamentos matemáticos pesados de forma distribuída (cálculo de distâncias geográficas pela Fórmula de Haversine e renderização automatizada do mapa do percurso final consumindo a Static Maps API), disparando o envio de relatórios em formato PDF e e-mails de confirmação sem onerar o servidor principal.
    * **Painel Web Desktop (Next.js):** Aplicação frontend corporativa que provê dashboards analíticos construídos com Tailwind CSS e Recharts, permitindo o gerenciamento do cadastro de múltiplos pets pelos tutores e a visualização do histórico financeiro e notas de reputação pelos passeadores.
* **Artefatos de Infraestrutura e Nuvem (Cloud Architecture):**
    * **Ambiente de Dados Local e Cloud:** Configuração de orquestração via Docker Compose isolando contêineres locais para desenvolvimento rápido, e provisionamento produtivo na AWS RDS (PostgreSQL hospedado em nuvem sob políticas de VPC privada) e AWS Amazon MQ (gerenciamento gerenciado do cluster RabbitMQ para controle das filas de notificações e relatórios).
    * **Deploy Automatizado:** Hospedagem ativa do ecossistema distribuído dividida entre a plataforma Render (para os serviços de Backend e Background Worker) e a plataforma Vercel (para distribuição global do painel Web).

### 4. Conclusões
O encerramento do projeto PetTrail atesta o cumprimento estrito de todos os objetivos propostos originalmente no Termo de Abertura. A plataforma conseguiu transpor a barreira da desconfiança do serviço informal de passeadores ao consolidar uma arquitetura de monitoramento em tempo real totalmente documentada, performática e segura. A validação das entregas demonstra que os requisitos funcionais (como o rastreamento síncrono e a geração de históricos) e não funcionais (como a latência controlada e o isolamento de credenciais via variáveis de ambiente) foram plenamente atendidos dentro do cronograma limite fixado de 24/03/2026 a 01/07/2026.

As principais contribuições do projeto residem na entrega de um ecossistema pronto para produção que profissionaliza os passeadores autônomos ao lhes conferir reputação digital auditável, enquanto entrega paz de espírito aos tutores.

#### Lições Aprendidas

1. **Desacoplamento e Resiliência via Mensageria Assíncrona:** A implementação de uma fila de mensagens (RabbitMQ via AWS Amazon MQ) para separar o fluxo principal da API (NestJS) do processamento de relatórios (Node.js Worker) provou ser vital. Aprendemos que delegar tarefas computacionalmente custosas, como o cálculo da Fórmula de Haversine e requisições externas para a Static Maps API, impede a degradação de performance da API e evita quedas nas conexões WebSocket ativas dos usuários.
2. **Complexidade do Gerenciamento de Ciclo de Vida Mobile em Segundo Plano:** O desenvolvimento do módulo de rastreamento contínuo utilizando o Flutter e o plugin Geolocator trouxe um profundo aprendizado sobre o gerenciamento de energia e permissões dos sistemas operacionais móveis. Foi necessário compreender as minúcias e restrições severas do Android e iOS quanto à execução de *Background Services* para garantir que o aplicativo do passeador não fosse encerrado pelo sistema operacional durante trajetos longos.
3. **Gerenciamento de Estados Distribuídos Híbridos:** A combinação entre bancos de dados relacionais e em tempo real trouxe um grande aprendizado arquitetural. A equipe assimilou a estratégia de delegar os dados voláteis de sessão ativa (coordenadas brutas de telemetria instantânea) para o Firebase Realtime Database, enquanto os dados consolidados, históricos imutáveis, cadastros e relatórios finais estruturados foram mantidos de forma segura no PostgreSQL via AWS RDS.
4. **Governança Estrita de Cotas de APIs e Orçamentos Cloud:** Como o requisito não funcional estipulava a permanência da aplicação dentro do nível gratuito (*Free Tier*) dos provedores (AWS e Google Maps Platform), aprendemos a importância do desenvolvimento de código otimizado. Isso exigiu a limitação inteligente da taxa de amostragem de envio de coordenadas GPS fixada em 5 segundos e o agrupamento de chamadas à API de mapas para evitar cobranças excedentes ou estouro de limites durante os testes de estresse da plataforma.
5. **Importância do Alinhamento Contínuo e Governança de Equipe:** No aspecto gerencial, o projeto solidificou o valor das metodologias ágeis de documentação. A manutenção rigorosa de atas de alinhamento semanais e relatórios de contribuição individual permitiu identificar desvios de escopo e gargalos técnicos logo no início das Sprints 2 e 3, garantindo uma distribuição equitativa das tarefas de Engenharia de Software e o cumprimento do prazo final sem a necessidade de prorrogações.
