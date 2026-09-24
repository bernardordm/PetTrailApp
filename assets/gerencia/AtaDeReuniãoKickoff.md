# Ata de Reunião Kickoff - PetTrail

## Informações
**Data/hora:** 21/03/2026, 19:00  
**Local:** Reunião virtual (Google Meet)  
**Motivo da reunião:** Kickoff do projeto PetTrail  
**Secretário:** N/A

## Participantes
Estiveram presentes na reunião:
- Bernardo de Resende Marcelino
- Flávio de Souza Júnior
- João Marcelo Carvalho Pereira Araújo
- Luidi Cadete Silva
- Miguel Figueiredo Diniz

## Pauta

Item | Descrição
---- | ----
Item de Agenda 1 | Apresentação do projeto PetTrail e validação do Termo de Abertura de Projeto (TAP)
Item de Agenda 2 | Alinhamento do escopo — o que será feito e o que não será feito
Item de Agenda 3 | Definição das tecnologias e arquitetura do sistema
Item de Agenda 4 | Distribuição de papéis e responsabilidades entre os integrantes
Item de Agenda 5 | Definição do cronograma e das entregas previstas
Item de Agenda 6 | Aprovação formal do TAP e autorização para início do projeto

## Notas e Decisões

Item | Quem | Anotações |
---- | ---- | ---- |
Validação do TAP | Todos | O projeto PetTrail foi apresentado e validado pelos participantes |
Arquitetura do sistema | Todos | App mobile (Flutter) para donos e passeadores; painel web desktop (Next.js) para histórico e relatórios; backend unificado (NestJS) com WebSocket; microserviço (Node.js) para processamento assíncrono de relatórios |
Funcionalidades do escopo | Todos | Rastreamento GPS em tempo real, confirmação de início por código presencial, geração automática de relatório com mapa do trajeto, notificações via WebSocket |
Fora do escopo | Todos | Pagamento entre dono e passeador ocorrerá fora da plataforma; agendamento de passeios não fará parte desta entrega |
Tecnologias validadas | Todos | Flutter, Next.js, NestJS, Node.js, PostgreSQL (AWS RDS), RabbitMQ (AWS Amazon MQ), Google Maps APIs e Render para hospedagem |
Cronograma e custo | Todos | Prazo de 24/03/2026 a 01/07/2026 (100 horas / 3,5 meses); custo estimado de R$1.350,00 (hospedagem AWS e contas de desenvolvedor das lojas mobile) |
Aprovação do TAP | Todos | TAP aprovado na reunião; projeto autorizado a iniciar conforme escopo definido |

## Ações e pendências

| Feito (S/N)? | Item | Responsável | Data para solução |
| ---- | ---- | ---- | ---- |
| N | Configurar contas AWS (RDS e Amazon MQ) | Bernardo e Miguel | 31/03/2026 |
| N | Ativar APIs do Google Maps no Google Cloud Console | João Marcelo | 07/04/2026 |
| N | Configurar repositório e estrutura inicial do monorepo | Flávio e Luidi | 31/03/2026 |

## Outras notas e informações
N/A 