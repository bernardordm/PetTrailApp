<p align="center">
  <img src="code/frontend/public/logo.png" alt="PetTrail Logo" width="200"/>
</p>

<h1 align="center">PetTrail</h1>

<p align="center">
  Conectando tutores e passeadores com rastreamento em tempo real
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Next.js-000000?style=for-the-badge&logo=next.js&logoColor=white" alt="Next.js" />
  <img src="https://img.shields.io/badge/NestJS-E0234E?style=for-the-badge&logo=nestjs&logoColor=white" alt="NestJS" />
  <img src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
</p>

---

## Sumário

- [Sobre o Projeto](#sobre-o-projeto)
- [Objetivos](#objetivos)
- [Funcionalidades](#funcionalidades)
- [Arquitetura](#arquitetura)
- [Tecnologias](#tecnologias)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [Como Executar](#como-executar)
- [Requisitos](#requisitos)
- [Equipe](#equipe)
- [Orientadores](#orientadores)

---

## Sobre o Projeto

O **PetTrail** é uma plataforma completa (mobile + web) que conecta **tutores de pets** a **passeadores autônomos** em ambiente urbano. O sistema foi desenvolvido para profissionalizar e digitalizar o mercado de passeio com pets no Brasil — o terceiro maior mercado pet do mundo, movimentando **R$ 75,4 bilhões em 2024** e ainda amplamente operado de forma informal.

A plataforma oferece rastreamento GPS em tempo real durante os passeios, confirmação presencial por QR Code, geração automática de relatórios com o trajeto percorrido e um sistema de avaliações entre tutores e passeadores.

---

## Objetivos

### Objetivo Geral
Desenvolver uma solução digital que facilite a conexão entre tutores e passeadores de pets, garantindo segurança, transparência e monitoramento em tempo real durante os passeios.

### Objetivos Específicos

- Permitir que tutores localizem passeadores disponíveis próximos à sua localização em um mapa interativo
- Oferecer rastreamento GPS em segundo plano nos dispositivos dos passeadores, transmitindo a localização em tempo real aos tutores
- Implementar confirmação presencial de início de passeio via QR Code para garantir segurança ao tutor
- Gerar relatórios automáticos ao final de cada passeio com métricas de distância, duração e imagem do trajeto
- Disponibilizar painéis web para tutores e passeadores acompanharem histórico, métricas e desempenho
- Criar um sistema de avaliações que permita construção de reputação pelos passeadores

---

## Funcionalidades

### Para Tutores (Donos de Pets)

| Funcionalidade | Descrição |
|---|---|
| Cadastro e perfil | Criação de conta com dados pessoais e perfis dos pets |
| Mapa de passeadores | Visualização de passeadores disponíveis em raio próximo |
| Solicitação de passeio | Envio de solicitação com código de confirmação de 6 dígitos |
| Rastreamento em tempo real | Acompanhamento do percurso do pet desenhado ao vivo no mapa |
| Relatório pós-passeio | Recebimento de relatório com trajeto, distância e duração |
| Avaliação | Avaliação do passeador de 1 a 5 estrelas ao final do passeio |
| Histórico | Acesso ao histórico completo de passeios via painel web |

### Para Passeadores

| Funcionalidade | Descrição |
|---|---|
| Cadastro e perfil | Criação de conta com documentação, precificação e foto |
| Disponibilidade | Ativação/desativação de disponibilidade (visível no mapa) |
| Recebimento de solicitações | Notificações de novas solicitações de passeio |
| Confirmação de chegada | Validação presencial via código fornecido pelo tutor |
| GPS em segundo plano | Transmissão da localização a cada 5 segundos durante o passeio |
| Encerramento de passeio | Finalização do passeio com geração automática de relatório |
| Painel de métricas | Dashboard web com histórico, avaliações e métricas mensais |

---

## Arquitetura

O PetTrail utiliza uma arquitetura de microserviços com comunicação assíncrona via mensageria:

```
┌─────────────────┐     REST/WS      ┌─────────────────────────────┐
│  App Mobile     │ ◄──────────────► │         Backend API         │
│  (Flutter)      │                  │         (NestJS)            │
└─────────────────┘                  └──────────┬──────────────────┘
                                                │
┌─────────────────┐     REST         │          │ RabbitMQ
│  Dashboard Web  │ ◄──────────────► │          ▼
│  (Next.js)      │                  ┌──────────────────────┐
└─────────────────┘                  │  Worker / Relatorios │
                                     │  (Node.js)           │
                                     └──────────────────────┘
         ┌───────────────────────────────────────────┐
         │           Infraestrutura de Dados          │
         │  PostgreSQL (AWS RDS) │ Firebase Realtime  │
         │  Firebase Storage     │ Google Maps APIs   │
         └───────────────────────────────────────────┘
```

### Fluxo de um Passeio

1. Tutor visualiza passeadores disponíveis no mapa e envia solicitação
2. Passeador recebe notificação, aceita e se desloca até o local
3. Ao chegar, passeador insere o **código de 6 dígitos** fornecido pelo tutor — confirmação presencial
4. Passeio inicia: GPS captura coordenadas a cada 5 segundos via **WebSocket**
5. Tutor acompanha o percurso sendo desenhado em tempo real
6. Ao finalizar, o backend publica uma mensagem no **RabbitMQ**
7. O **Worker** processa o relatório de forma assíncrona (trajeto, distância, duração)
8. Tutor e passeador avaliam a experiência mutuamente

### Comunicação

| Canal | Protocolo | Uso |
|---|---|---|
| App ↔ Backend | REST API | CRUD, autenticação, histórico |
| App ↔ Backend | WebSocket | Transmissão de coordenadas GPS em tempo real |
| Backend ↔ Worker | RabbitMQ | Geração assíncrona de relatórios |
| App ↔ Firebase | Realtime Database | Estado da sessão de passeio |

---

## Tecnologias

### Mobile (Flutter)

| Tecnologia | Versão | Uso |
|---|---|---|
| Flutter / Dart | 3.x | Framework principal mobile (iOS & Android) |
| Google Maps Flutter | 2.10.0 | Mapas e rastreamento no app |
| Geolocator | 13.0.4 | Captura de GPS em segundo plano |
| QR Flutter | 4.1.0 | Geração de QR Code |
| Mobile Scanner | 7.1.2 | Leitura de QR Code |
| Firebase Core + Database | latest | Integração Firebase |
| HTTP | 1.6.0 | Comunicação com a API |
| Shared Preferences | 2.5.5 | Armazenamento local |
| Image Picker | 1.0.4 | Seleção de fotos do perfil |

### Frontend Web (Next.js)

| Tecnologia | Versão | Uso |
|---|---|---|
| Next.js | 16.2.0 | Framework React SSR/SSG |
| React | 19.2.4 | Biblioteca de UI |
| Tailwind CSS | 4.2.0 | Estilização |
| @react-google-maps/api | 2.20.8 | Mapas no painel web |
| Firebase | 12.12.1 | Autenticação e dados em tempo real |
| Recharts | 2.15.0 | Gráficos e analytics |
| React Hook Form | 7.54.1 | Gerenciamento de formulários |
| Zod | 3.24.1 | Validação de schemas |
| Radix UI | latest | Componentes acessíveis (modais, acordeões etc.) |
| React Easy Crop | 5.5.7 | Recorte de imagens de perfil |

### Backend API (NestJS)

| Tecnologia | Versão | Uso |
|---|---|---|
| NestJS | 11.0.1 | Framework Node.js |
| TypeORM | 0.3.x | ORM e migrações |
| PostgreSQL (pg) | 8.20.0 | Banco de dados relacional |
| JWT + Passport | 11.0.x | Autenticação e autorização |
| Firebase Admin | 13.7.0 | Integração Firebase server-side |
| bcrypt | 6.0.0 | Hash de senhas |
| class-validator | latest | Validação de DTOs |

### Worker / Microserviço

| Tecnologia | Uso |
|---|---|
| NestJS (Node.js) | Framework do microserviço |
| RabbitMQ (Amazon MQ) | Consumo de filas de relatórios |

### Infraestrutura & Cloud

| Serviço | Uso |
|---|---|
| AWS RDS (PostgreSQL) | Banco de dados relacional em nuvem |
| AWS Amazon MQ (RabbitMQ) | Mensageria assíncrona |
| Firebase Realtime Database | Dados de sessão em tempo real |
| Firebase Storage | Armazenamento de imagens de perfil |
| Render | Hospedagem do backend e worker |
| Vercel | Hospedagem do frontend web |
| Google Maps Platform | Maps SDK, Static Maps, Directions, Geocoding |

---

## Estrutura do Repositório

```
pet-trail/
├── code/
│   ├── backend/          # API principal (NestJS)
│   │   └── src/
│   │       ├── app/
│   │       ├── domains/
│   │       │   ├── auth/
│   │       │   ├── users/
│   │       │   ├── tutors/
│   │       │   ├── walkers/
│   │       │   ├── pets/
│   │       │   └── tours/
│   │       └── database/
│   ├── frontend/         # Painel web (Next.js)
│   │   └── src/
│   │       ├── app/
│   │       ├── components/
│   │       └── shared/
│   ├── mobile/           # App mobile (Flutter)
│   │   └── lib/
│   │       ├── screens/
│   │       ├── widgets/
│   │       ├── domain/
│   │       ├── data/
│   │       └── theme/
│   └── worker/           # Microserviço de relatórios (Node.js)
├── docs/                 # Documentação técnica e de produto
├── assets/               # Artefatos de gerência e atas
└── divulge/              # Materiais de apresentação e vídeos
```

---

## Como Executar

### Pré-requisitos

- [Node.js](https://nodejs.org/) >= 20
- [Flutter SDK](https://flutter.dev/) >= 3.x
- [PostgreSQL](https://www.postgresql.org/) >= 15 (ou acesso ao AWS RDS)
- Conta no Firebase com projeto configurado
- Chave da API do Google Maps

### Backend

```bash
cd code/backend
cp .env.example .env   # configure as variáveis de ambiente
npm install
npm run migration:run  # executa as migrações do banco
npm run start:dev
```

O servidor sobe em `http://localhost:3001`.

### Frontend Web

```bash
cd code/frontend
cp .env.example .env   # configure NEXT_PUBLIC_API_URL e chaves Firebase/Google Maps
npm install
npm run dev
```

Acesse em `http://localhost:3000`.

### Mobile

```bash
cd code/mobile
flutter pub get
flutter run
```

> Configure `lib/config/app_config.dart` com a URL da API antes de rodar.

### Worker

```bash
cd code/worker
npm install
npm run start:dev
```

---

## Requisitos

### Funcionais

| ID | Requisito |
|---|---|
| RF001 | Cadastro e autenticação de tutores e passeadores |
| RF002 | Gerenciamento de perfil de pets pelo tutor |
| RF003 | Passeador pode ativar/desativar disponibilidade |
| RF004 | Tutor visualiza passeadores disponíveis em mapa próximo |
| RF005 | Tutor solicita passeio e recebe código de confirmação |
| RF006 | Passeador recebe notificação de solicitação e aceita/recusa |
| RF007 | Confirmação presencial de início via código de 6 dígitos |
| RF008 | Rastreamento GPS em segundo plano pelo passeador |
| RF009 | Tutor acompanha o percurso em tempo real no mapa |
| RF010 | Encerramento do passeio pelo passeador |
| RF011 | Geração automática de relatório pós-passeio (trajeto, distância, duração) |
| RF012 | Sistema de avaliação mútua tutor ↔ passeador (1–5 estrelas) |
| RF013 | Painel web com histórico de passeios para tutores |
| RF014 | Painel web com métricas e histórico para passeadores |
| RF015 | Gerenciamento de status de passeio (pendente, em andamento, concluído) |

### Não Funcionais

| ID | Requisito |
|---|---|
| RNF001 | Latência máxima de 30 segundos para atualizações de GPS |
| RNF002 | Alta disponibilidade do backend |
| RNF003 | Escalabilidade horizontal via RabbitMQ |
| RNF004 | Autenticação JWT com controle de acesso por papel (tutor/passeador) |
| RNF005 | Credenciais exclusivamente via variáveis de ambiente |
| RNF006 | Banco de dados em AWS RDS com backups e isolamento em VPC |
| RNF007 | Geração de relatórios assíncrona sem bloqueio ao finalizar o passeio |
| RNF008 | GPS em segundo plano funcional em iOS e Android |
| RNF009 | Interface web responsiva |
| RNF010 | Uso dentro do nível gratuito do Google Maps e AWS |

---

## Equipe

| Nome | GitHub |
|---|---|
| Bernardo de Resende Marcelino | https://github.com/bernardordm |
| Flávio de Souza Júnior | https://github.com/flaviojuniordev |
| João Marcelo Carvalho Pereira Araújo | https://github.com/joaomarcelocpa |
| Luidi Cadete Silva |https://github.com/LuidiC |
| Miguel Figueiredo Diniz | https://github.com/DevMiguelDiniz |

---

## Orientadores

- Cleiton Silva Tavares
- Leonardo Vilela Cardoso
- Arthur Martins Mol

---

<p align="center">
  Desenvolvido na disciplina de <strong>Trabalho Interdisciplinar: Aplicações Distríbuidas</strong>
</p>
