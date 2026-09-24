<p align="center">
  <img src="code/frontend/public/logo.png" alt="PetTrail Logo" width="200"/>
</p>

<h1 align="center">PetTrail</h1>

<p align="center">
  Connecting pet owners and dog walkers with real-time tracking
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Next.js-000000?style=for-the-badge&logo=next.js&logoColor=white" alt="Next.js" />
  <img src="https://img.shields.io/badge/NestJS-E0234E?style=for-the-badge&logo=nestjs&logoColor=white" alt="NestJS" />
  <img src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
</p>

> **Note:** This is the public version of a group project developed during our undergraduate studies at PUC Minas, as part of the *Interdisciplinary Work: Distributed Applications* course.

---

## Table of Contents

- [About the Project](#about-the-project)
- [Goals](#goals)
- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [How to Run](#how-to-run)
- [Requirements](#requirements)
- [Team](#team)
- [Advisors](#advisors)

---

## About the Project

**PetTrail** is a full-stack platform (mobile + web) that connects **pet owners** with **independent dog walkers** in urban environments. The system was built to professionalize and digitize the pet walking market in Brazil — the third largest pet market in the world, generating **R$ 75.4 billion in 2024**, yet still largely operating informally.

The platform provides real-time GPS tracking during walks, on-site confirmation via QR Code, automatic post-walk report generation with the route taken, and a mutual rating system between owners and walkers.

---

## Goals

### General Goal
Develop a digital solution that facilitates the connection between pet owners and dog walkers, ensuring safety, transparency, and real-time monitoring throughout each walk.

### Specific Goals

- Allow owners to find available walkers near their location on an interactive map
- Provide background GPS tracking on walkers' devices, transmitting their location in real time to owners
- Implement on-site walk confirmation via a QR Code to ensure owner safety
- Automatically generate post-walk reports with distance, duration, and a route image
- Offer web dashboards for both owners and walkers to view history, metrics, and performance
- Build a rating system that allows walkers to establish reputation over time

---

## Features

### For Pet Owners

| Feature | Description |
|---|---|
| Account & profile | Registration with personal details and pet profiles |
| Walker map | View available walkers within a nearby radius |
| Walk request | Send a request with a 6-digit confirmation code |
| Real-time tracking | Follow the pet's route being drawn live on the map |
| Post-walk report | Receive a report with route, distance, and duration |
| Rating | Rate the walker from 1 to 5 stars after the walk |
| History | Access full walk history via the web dashboard |

### For Dog Walkers

| Feature | Description |
|---|---|
| Account & profile | Registration with documentation, pricing, and photo |
| Availability toggle | Enable/disable availability (visible on the map) |
| Walk requests | Receive notifications for new walk requests |
| Arrival confirmation | On-site validation via code provided by the owner |
| Background GPS | Location transmitted every 5 seconds during the walk |
| Walk completion | End the walk and trigger automatic report generation |
| Metrics dashboard | Web dashboard with history, ratings, and monthly metrics |

---

## Architecture

PetTrail uses a microservices architecture with asynchronous communication via message queuing:

```
┌─────────────────┐     REST/WS      ┌─────────────────────────────┐
│  Mobile App     │ ◄──────────────► │         Backend API         │
│  (Flutter)      │                  │         (NestJS)            │
└─────────────────┘                  └──────────┬──────────────────┘
                                                │
┌─────────────────┐     REST         │          │ RabbitMQ
│  Web Dashboard  │ ◄──────────────► │          ▼
│  (Next.js)      │                  ┌──────────────────────┐
└─────────────────┘                  │  Worker / Reports    │
                                     │  (Node.js)           │
                                     └──────────────────────┘
         ┌───────────────────────────────────────────┐
         │              Data Infrastructure           │
         │  PostgreSQL (AWS RDS) │ Firebase Realtime  │
         │  Firebase Storage     │ Google Maps APIs   │
         └───────────────────────────────────────────┘
```

### Walk Flow

1. Owner views available walkers on the map and sends a request
2. Walker receives a notification, accepts, and heads to the location
3. On arrival, the walker enters the **6-digit code** provided by the owner — on-site confirmation
4. Walk begins: GPS captures coordinates every 5 seconds via **WebSocket**
5. Owner watches the route being drawn in real time
6. On completion, the backend publishes a message to **RabbitMQ**
7. The **Worker** processes the report asynchronously (route, distance, duration)
8. Owner and walker rate each other

### Communication Channels

| Channel | Protocol | Purpose |
|---|---|---|
| App ↔ Backend | REST API | CRUD, authentication, history |
| App ↔ Backend | WebSocket | Real-time GPS coordinate streaming |
| Backend ↔ Worker | RabbitMQ | Asynchronous report generation |
| App ↔ Firebase | Realtime Database | Walk session state |

---

## Tech Stack

### Mobile (Flutter)

| Technology | Version | Purpose |
|---|---|---|
| Flutter / Dart | 3.x | Main mobile framework (iOS & Android) |
| Google Maps Flutter | 2.10.0 | Maps and tracking in the app |
| Geolocator | 13.0.4 | Background GPS capture |
| QR Flutter | 4.1.0 | QR Code generation |
| Mobile Scanner | 7.1.2 | QR Code scanning |
| Firebase Core + Database | latest | Firebase integration |
| HTTP | 1.6.0 | API communication |
| Shared Preferences | 2.5.5 | Local storage |
| Image Picker | 1.0.4 | Profile photo selection |

### Web Frontend (Next.js)

| Technology | Version | Purpose |
|---|---|---|
| Next.js | 16.2.0 | React SSR/SSG framework |
| React | 19.2.4 | UI library |
| Tailwind CSS | 4.2.0 | Styling |
| @react-google-maps/api | 2.20.8 | Maps in the web dashboard |
| Firebase | 12.12.1 | Authentication and real-time data |
| Recharts | 2.15.0 | Charts and analytics |
| React Hook Form | 7.54.1 | Form management |
| Zod | 3.24.1 | Schema validation |
| Radix UI | latest | Accessible components (modals, accordions, etc.) |
| React Easy Crop | 5.5.7 | Profile image cropping |

### Backend API (NestJS)

| Technology | Version | Purpose |
|---|---|---|
| NestJS | 11.0.1 | Node.js framework |
| TypeORM | 0.3.x | ORM and migrations |
| PostgreSQL (pg) | 8.20.0 | Relational database |
| JWT + Passport | 11.0.x | Authentication and authorization |
| Firebase Admin | 13.7.0 | Server-side Firebase integration |
| bcrypt | 6.0.0 | Password hashing |
| class-validator | latest | DTO validation |

### Worker / Microservice

| Technology | Purpose |
|---|---|
| NestJS (Node.js) | Microservice framework |
| RabbitMQ (Amazon MQ) | Report queue consumption |

### Infrastructure & Cloud

| Service | Purpose |
|---|---|
| AWS RDS (PostgreSQL) | Relational database in the cloud |
| AWS Amazon MQ (RabbitMQ) | Asynchronous messaging |
| Firebase Realtime Database | Real-time session data |
| Firebase Storage | Profile image storage |
| Render | Backend and worker hosting |
| Vercel | Web frontend hosting |
| Google Maps Platform | Maps SDK, Static Maps, Directions, Geocoding |

---

## Repository Structure

```
pet-trail/
├── code/
│   ├── backend/          # Main API (NestJS)
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
│   ├── frontend/         # Web dashboard (Next.js)
│   │   └── src/
│   │       ├── app/
│   │       ├── components/
│   │       └── shared/
│   ├── mobile/           # Mobile app (Flutter)
│   │   └── lib/
│   │       ├── screens/
│   │       ├── widgets/
│   │       ├── domain/
│   │       ├── data/
│   │       └── theme/
│   └── worker/           # Reports microservice (Node.js)
├── docs/                 # Technical and product documentation
├── assets/               # Management artifacts and meeting notes
└── divulge/              # Presentation materials and videos
```

---

## How to Run

### Prerequisites

- [Node.js](https://nodejs.org/) >= 20
- [Flutter SDK](https://flutter.dev/) >= 3.x
- [PostgreSQL](https://www.postgresql.org/) >= 15 (or access to AWS RDS)
- Firebase project configured
- Google Maps API key

### Backend

```bash
cd code/backend
cp .env.example .env   # configure environment variables
npm install
npm run migration:run  # run database migrations
npm run start:dev
```

Server runs at `http://localhost:3001`.

### Web Frontend

```bash
cd code/frontend
cp .env.example .env   # configure NEXT_PUBLIC_API_URL and Firebase/Google Maps keys
npm install
npm run dev
```

Access at `http://localhost:3000`.

### Mobile

```bash
cd code/mobile
flutter pub get
flutter run
```

> Configure `lib/config/app_config.dart` with the API URL before running.
>
> The Google Maps API key must be set in `android/local.properties` as `MAPS_API_KEY=<your_key>`.

### Worker

```bash
cd code/worker
npm install
npm run start:dev
```

---

## Requirements

### Functional

| ID | Requirement |
|---|---|
| FR001 | Registration and authentication for owners and walkers |
| FR002 | Pet profile management by the owner |
| FR003 | Walker can toggle availability on/off |
| FR004 | Owner views available walkers on a nearby map |
| FR005 | Owner requests a walk and receives a confirmation code |
| FR006 | Walker receives walk request notification and accepts/declines |
| FR007 | On-site walk start confirmation via 6-digit code |
| FR008 | Background GPS tracking by the walker |
| FR009 | Owner follows the route in real time on the map |
| FR010 | Walker ends the walk |
| FR011 | Automatic post-walk report generation (route, distance, duration) |
| FR012 | Mutual rating system owner ↔ walker (1–5 stars) |
| FR013 | Web dashboard with walk history for owners |
| FR014 | Web dashboard with metrics and history for walkers |
| FR015 | Walk status management (pending, in progress, completed) |

### Non-Functional

| ID | Requirement |
|---|---|
| NFR001 | Maximum 30-second latency for GPS updates |
| NFR002 | High availability of the backend |
| NFR003 | Horizontal scalability via RabbitMQ |
| NFR004 | JWT authentication with role-based access control (owner/walker) |
| NFR005 | Credentials exclusively via environment variables |
| NFR006 | Database on AWS RDS with backups and VPC isolation |
| NFR007 | Asynchronous report generation without blocking walk completion |
| NFR008 | Background GPS functional on both iOS and Android |
| NFR009 | Responsive web interface |
| NFR010 | Usage within the free tier of Google Maps and AWS |

---

## Team

| Name | GitHub |
|---|---|
| Bernardo de Resende Marcelino | https://github.com/bernardordm |
| Flávio de Souza Júnior | https://github.com/flaviojuniordev |
| João Marcelo Carvalho Pereira Araújo | https://github.com/joaomarcelocpa |
| Luidi Cadete Silva | https://github.com/LuidiC |
| Miguel Figueiredo Diniz | https://github.com/DevMiguelDiniz |

---

## Advisors

- Cleiton Silva Tavares
- Leonardo Vilela Cardoso
- Arthur Martins Mol

---

<p align="center">
  Developed as part of the <strong>Interdisciplinary Work: Distributed Applications</strong> course
</p>
