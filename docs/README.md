# PetTrail


**Bernardo de Resende Marcelino, bernardo.marcelino@sga.pucminas.br**

**Flávio de Souza Júnior, flavio.junior.1528822@sga.pucminas.br**

**João Marcelo Carvalho Pereira Araújo, jmcparaujo@sga.pucminas.br**

**Luidi Cadete Silva, luidi.cadete@sga.pucminas.br**

**Miguel Figueiredo Diniz, miguel.diniz@sga.pucminas.br**

---

Professores:

**Prof. Cleiton Silva Tavares**

**Prof. Leonardo Vilela Cardoso**

**Prof. Arthur Martins Mol**


---

_Curso de Engenharia de Software, Campus Lourdes_

_Instituto de Informática e Ciências Exatas – Pontifícia Universidade de Minas Gerais (PUC MINAS), Belo Horizonte – MG – Brasil_

---

_**Resumo**. O mercado pet brasileiro é o terceiro maior do mundo, mas a contratação de passeadores ainda ocorre de forma predominantemente informal, sem rastreabilidade ou transparência para os tutores. O PetTrail é uma plataforma mobile e web que conecta tutores urbanos a passeadores autônomos, oferecendo rastreamento em tempo real do trajeto do pet com trilha crescente ponto a ponto, confirmação presencial por código na retirada do animal, geração automática de relatório ao término do passeio e sistema de avaliação mútua entre tutores e passeadores. A solução é desenvolvida com arquitetura de microserviços utilizando Flutter, Next.js, Nest.js, PostgreSQL, WebSocket e RabbitMQ, com foco em escalabilidade, confiabilidade e experiência do usuário._

---

## SUMÁRIO

1. [Apresentação](1.apresentacao.md#apresentacao "Apresentação") <br />
	1.1. Problema <br />
	1.2. Objetivos do trabalho <br />
	1.3. Definições e Abreviaturas <br />
 
2. [Nosso Produto](2.nosso_produto.md#produto "Nosso Produto") <br />
	2.1. Visão do Produto <br />
   	2.2. Nosso Produto <br />
   	2.3. Personas <br />

3. [Requisitos](3.requisitos.md#requisitos "Requisitos") <br />
	3.1. Requisitos Funcionais <br />
	3.2. Requisitos Não-Funcionais <br />
	3.3. Restrições Arquiteturais <br />
	3.4. Mecanismos Arquiteturais <br />

4. [Modelagem](4.modelagem.md#modelagem "Modelagem e projeto arquitetural") <br />
	4.1. Histórias de Usuário <br />
	4.2. Visão Lógica <br />
	4.3. Modelo de Dados <br />

5. [Wireframes](5.wireframe.md#wireframes "Wireframes") <br />
	5.1. Tela de Login <br />
	5.2. Home (Visão Tutor) <br />
	5.3. Lista de Passeios <br />
	5.4. Relatórios e Métricas <br />
	5.5. Perfil do Usuário <br />
	5.6. Gestão de Pets <br />

6. [Solução](6.solucao.md#solucao "Projeto da Solução") <br />
	6.1. Telas Mobile <br />
	6.2. Telas Web <br />

7. [Avaliação](7.avaliacao.md#avaliacao "Avaliação da Arquitetura") <br />
	7.1. Cenários <br />
	7.2. Avaliação <br />

[Referências](1.apresentacao.md#referencias "Referências")<br />

[Ferramentas](#ferramentas "Ferramentas")<br />

<a name="ferramentas"></a>
# Ferramentas

_Inclua o URL do repositório (Github, Bitbucket, etc) onde você armazenou o código da sua prova de conceito/protótipo arquitetural da aplicação como anexos. A inclusão da URL desse repositório de código servirá como base para garantir a autenticidade dos trabalhos._

| Ambiente  | Plataforma              |Link de Acesso |
|-----------|-------------------------|---------------|
|Repositório de código | GitHub | https://github.com/ICEI-PUC-Minas-PMGES-TI/pmg-es-2026-1-ti5-6904100-pet-trail |
|Hospedagem do site | Vercel | https://pettrail.vercel.app/login |
|Protótipo Interativo | - | - |
