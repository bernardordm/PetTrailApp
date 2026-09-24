export default () => ({
  port: parseInt(process.env.PORT ?? '3003', 10),
  database: {
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT ?? '5432', 10),
    username: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    name: process.env.DB_NAME,
    ssl: process.env.DB_SSL === 'true',
  },
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRATION ?? '7d',
  },
  rabbitmq: {
    url: process.env.RABBITMQ_URL,
    chatQueue: process.env.RABBITMQ_CHAT_QUEUE,
    chatDlq: process.env.RABBITMQ_CHAT_DLQ,
  },
});
