.PHONY: dev backend worker chat-service frontend install build

# Inicia todos os serviços em paralelo (modo desenvolvimento)
dev:
	$(MAKE) -j4 backend worker chat-service frontend

# Serviços individuais
backend:
	cd backend && npm run start:dev

worker:
	cd worker && npm run start:dev

chat-service:
	cd chat-service && npm run start:dev

frontend:
	cd frontend && npm run dev

# Instala dependências de todos os serviços
install:
	cd backend && npm install
	cd worker && npm install
	cd chat-service && npm install
	cd frontend && npm install

# Build de produção de todos os serviços Node/Next
build:
	cd backend && npm run build
	cd worker && npm run build
	cd chat-service && npm run build
	cd frontend && npm run build
