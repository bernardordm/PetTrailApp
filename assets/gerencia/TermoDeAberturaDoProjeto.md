# Termo de Abertura de Projeto (TAP) no.: 9999

**Nome da empresa:** PUC Minas

**Data:** 24/03/2026

**Integrantes:**

- Bernardo de Resende Marcelino
- Flávio de Souza Júnior
- João Marcelo Carvalho Pereira Araújo
- Luidi Cadete Silva
- Miguel Figueiredo Diniz

---

**Professores:**

- Cleiton Silva Tavares
- Leonardo Vilela Cardoso
- Arthur Martins Mol

---

_Curso de Engenharia de Software, Unidade Praça da Liberdade_

_Instituto de Informática e Ciências Exatas – Pontifícia Universidade de Minas Gerais (PUC MINAS), Belo Horizonte – MG – Brasil_

---

## 1. IDENTIFICAÇÃO DO PROJETO

**1.1 Nome do Projeto:** PetTrail

**1.2 Gerente do Projeto:** João Marcelo Carvalho Pereira Araújo

**1.3 Cliente do Projeto:** PUC Minas

**1.4 Tipo de Projeto:**

- [ ] Manutenção em produto existente
- [x] Desenvolvimento de novo produto
- [ ] Outro: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

**1.5 Objetivo do projeto:**

Desenvolver o PetTrail, uma plataforma digital de passeio de pets que conecta donos de animais de estimação a passeadores autônomos. O sistema permitirá que donos localizem passeadores disponíveis em tempo real por meio de um mapa, solicitem passeios imediatos, acompanhem o trajeto do pet com rastreamento GPS e recebam um relatório automático ao final de cada passeio. O objetivo é transformar um serviço atualmente informal e sem rastreabilidade em uma experiência segura, transparente e documentada para ambos os lados.

**1.6 Benefícios que justificam o projeto:**

O projeto trará benefícios ao resolver a falta de transparência e confiança no serviço de passeio de pets, que hoje é contratado de forma informal, sem registro e sem visibilidade do que acontece durante o passeio. Para os donos, o sistema oferece tranquilidade ao permitir acompanhar o pet em tempo real e receber comprovação automática do serviço. Para os passeadores autônomos, a plataforma oferece visibilidade, credibilidade e um histórico verificável de avaliações que valoriza seu trabalho. O mercado pet brasileiro é o 3º maior do mundo, com faturamento de R$ 75,4 bilhões em 2024 (Abinpet/IPB), e o segmento de serviços como passeio segue majoritariamente informal, representando uma lacuna real de mercado a ser endereçada.

**1.7 Qualidade esperada do produto final (requisitos de qualidade):**

O sistema deverá apresentar facilidade de uso, permitindo que donos e passeadores utilizem o app mobile de forma simples e intuitiva. Deverá garantir confiabilidade no rastreamento GPS, transmitindo as coordenadas em tempo real sem perda de pontos durante o passeio. O relatório automático deverá ser gerado corretamente ao final de cada passeio, contendo o mapa do trajeto, distância e duração. O sistema precisa ter bom desempenho, sustentando múltiplas conexões WebSocket simultâneas de forma estável. Além disso, deverá garantir segurança no processo de confirmação de início do passeio por código presencial e na autenticação separada por perfil de usuário.

## 2. ESCOPO PRELIMINAR E PREMISSAS

**2.1 O que será feito (escopo do projeto)**

Será desenvolvido um sistema completo de passeio de pets composto por app mobile (Flutter) para donos e passeadores, painel web desktop (Next.js) para consulta de histórico e relatórios, backend unificado (NestJS) com API REST e comunicação em tempo real via WebSocket, e microserviço (Node.js) para processamento assíncrono de relatórios.

O app permitirá que donos visualizem passeadores disponíveis no mapa, solicitem passeios imediatos, recebam o código de confirmação de início e acompanhem o trajeto em tempo real. Os passeadores poderão aceitar ou recusar solicitações, confirmar a chegada por código e iniciar o rastreamento GPS em segundo plano durante o passeio.

Ao finalizar, o microserviço processará os dados do passeio, gerará a imagem do trajeto via Static Maps API, enviará o relatório por e-mail ao dono e disparará uma notificação de conclusão via WebSocket. O sistema registrará todas as coordenadas coletadas, relatórios e avaliações em banco de dados PostgreSQL, com mensageria RabbitMQ para processamento assíncrono das filas de relatórios e notificações.

**2.2 O que não será feito no projeto (contra-escopo)**

O projeto não incluirá processamento de pagamentos, sendo o valor combinado diretamente entre dono e passeador fora da plataforma. Também não fará parte do escopo o rastreamento do passeador no trajeto até a casa do dono, agendamento de passeios, painel administrativo de gestão da plataforma, sistema de seguro ou garantia de serviço, e integração com serviços de veterinário ou pet shop. O sistema terá foco exclusivo na operação do passeio — da solicitação à entrega do relatório final.

**2.3 Resultados / serviços / produtos a serem entregues**

| | |
| --- | --- |
| **1.** | Aplicativo mobile funcional para Android e iOS, contemplando os fluxos completos de donos e passeadores |
| **2.** | Painel web desktop com histórico de passeios, relatórios e métricas para donos e passeadores |

**2.4 Condições para início do projeto**

O projeto poderá ser iniciado após a definição clara do escopo, das tecnologias a serem utilizadas e dos papéis da equipe. Também é necessário que o ambiente de desenvolvimento esteja configurado com Flutter SDK, Node.js, Android Studio e Xcode, e que as contas de serviços externos estejam criadas — Google Cloud Console com as APIs do Google Maps ativadas e AWS para o banco de dados e mensageria.

## 3. ESTIMATIVA DE PRAZO

**3.1 Prazo previsto (horas):** 100

**3.2 Data prevista de início:** 24 / 03 / 2026  
**3.3 Data prevista de término:** 01 / 07 / 2026

## 4. ESTIMATIVA DE CUSTO

| Item de custo | Qtd. horas | Valor / hora | Valor total |
| --- | --- | --- | --- |
| **4.1 Recursos Humanos:** 5 Desenvolvedores | 100 | R$ 0,00 | R$ 0,00 |
| **4.2 Hardware:** Computadores próprios dos desenvolvedores | — | — | R$ 0,00 |
| **4.3 Rede e serviços de hospedagem:** AWS Amazon MQ, AWS RDS, Render | — | — | R$ 630,00 |
| **4.4 Software de terceiros:** Maps APIs | — | — | R$ 0,00 |
| **4.5 Serviços e treinamento:** Google Play, Apple Developer | — | — | R$ 720,00 |
| **4.6 Total Geral:** | 100 | — | R$ 1.350,00 |

## 5. PARTES INTERESSADAS

| Nome | Papel no projeto | Assinatura |
| --- | --- | --- |
| Bernardo de Resende Marcelino | Gerente do projeto / Desenvolvedor | |
| Flávio de Souza Júnior | Gerente do projeto / Desenvolvedor | |
| João Marcelo Carvalho Pereira Araújo | Gerente do projeto / Desenvolvedor | |
| Luidi Cadete Silva | Gerente do projeto / Desenvolvedor | |
| Miguel Figueiredo Diniz | Gerente do projeto / Desenvolvedor | |

**Observações:**

- As estimativas de prazo e custo são aproximadas e podem variar ao longo do projeto, devendo ser revistas após o detalhamento dos requisitos.

- Este documento, após ser completamente preenchido, deve ser assinado pelos responsáveis do projeto (gestores envolvidos).

- Este documento, se aprovado na **reunião de** _**kickoff**_, autoriza o início do projeto de acordo com a especificação supra e as normas da empresa.