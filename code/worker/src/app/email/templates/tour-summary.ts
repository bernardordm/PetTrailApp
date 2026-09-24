export interface TourSummaryData {
  tutorName: string;
  petName: string;
  date: string;
  distance: string;
  duration: string;
  price: string;
  rating: string;
  walkerName: string;
  mapImageUrl: string | null;
}

export function tourSummaryHtml(data: TourSummaryData): string {
  const mapSection = data.mapImageUrl
    ? `
      <tr>
        <td style="padding:0 32px 28px;">
          <p style="margin:0 0 10px; font-size:11px; font-weight:600; color:#6b7280; text-transform:uppercase; letter-spacing:0.8px;">
            Trajeto percorrido
          </p>
          <img
            src="${data.mapImageUrl}"
            alt="Mapa do trajeto"
            width="536"
            style="width:100%; max-width:536px; border-radius:8px; border:1px solid #e5e7eb; display:block;"
          />
        </td>
      </tr>`
    : '';

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Resumo do Passeio — PetTrail</title>
</head>

<body style="margin:0; padding:0; background:#f3f4f6; font-family:Helvetica,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f3f4f6; padding:36px 16px;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0"
          style="max-width:600px; width:100%; background:#ffffff; border-radius:10px; overflow:hidden; border:1px solid #e5e7eb;">

          <!-- HEADER -->
          <tr>
            <td style="background:#ee5a52; padding:24px 32px 22px;">
              <p style="margin:0; font-size:22px; font-weight:700; color:#ffffff; letter-spacing:-0.5px; line-height:1;">
                PetTrail
              </p>
              <p style="margin:5px 0 0; font-size:12px; color:#fecaca; letter-spacing:0.4px;">
                Resumo do passeio
              </p>
            </td>
          </tr>

          <!-- TITLE -->
          <tr>
            <td style="padding:28px 32px 8px;">
              <p style="margin:0; font-size:18px; color:#111827; font-weight:700; line-height:1.4;">
                Passeio concluído com sucesso! 🐾
              </p>
            </td>
          </tr>

          <!-- GREETING -->
          <tr>
            <td style="padding:8px 32px 24px;">
              <p style="margin:0; font-size:14px; color:#374151; line-height:1.7;">
                Olá, <strong>${data.tutorName}</strong>! Temos ótimas notícias —
                <strong>${data.petName}</strong> chegou em segurança após o passeio realizado por
                <strong>${data.walkerName}</strong> em ${data.date}.
                Preparamos um resumo completo para você acompanhar tudo o que aconteceu.
              </p>
            </td>
          </tr>

          <!-- DIVIDER -->
          <tr>
            <td style="padding:0 32px 24px;">
              <div style="height:1px; background:#f3f4f6;"></div>
            </td>
          </tr>

          <!-- STATS -->
          <tr>
            <td style="padding:0 32px 28px;">
              <p style="margin:0 0 14px; font-size:11px; font-weight:600; color:#6b7280; text-transform:uppercase; letter-spacing:0.8px;">
                Resumo do passeio
              </p>
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td width="33%" style="padding-right:8px;">
                    <table width="100%" cellpadding="0" cellspacing="0"
                      style="border:1px solid #e5e7eb; border-radius:8px; overflow:hidden;">
                      <tr><td height="3" style="background:#ee5a52; font-size:0; line-height:0;">&nbsp;</td></tr>
                      <tr><td style="padding:14px 12px 16px; text-align:center;">
                        <p style="margin:0 0 4px; font-size:16px; font-weight:700; color:#111827;">${data.distance}</p>
                        <p style="margin:0; font-size:10px; color:#9ca3af; text-transform:uppercase; letter-spacing:0.8px;">Distância</p>
                      </td></tr>
                    </table>
                  </td>
                  <td width="33%" style="padding-right:8px;">
                    <table width="100%" cellpadding="0" cellspacing="0"
                      style="border:1px solid #e5e7eb; border-radius:8px; overflow:hidden;">
                      <tr><td height="3" style="background:#ee5a52; font-size:0; line-height:0;">&nbsp;</td></tr>
                      <tr><td style="padding:14px 12px 16px; text-align:center;">
                        <p style="margin:0 0 4px; font-size:16px; font-weight:700; color:#111827;">${data.duration}</p>
                        <p style="margin:0; font-size:10px; color:#9ca3af; text-transform:uppercase; letter-spacing:0.8px;">Duração</p>
                      </td></tr>
                    </table>
                  </td>
                  <td width="33%">
                    <table width="100%" cellpadding="0" cellspacing="0"
                      style="border:1px solid #e5e7eb; border-radius:8px; overflow:hidden;">
                      <tr><td height="3" style="background:#ee5a52; font-size:0; line-height:0;">&nbsp;</td></tr>
                      <tr><td style="padding:14px 12px 16px; text-align:center;">
                        <p style="margin:0 0 4px; font-size:16px; font-weight:700; color:#111827;">${data.price}</p>
                        <p style="margin:0; font-size:10px; color:#9ca3af; text-transform:uppercase; letter-spacing:0.8px;">Valor</p>
                      </td></tr>
                    </table>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          ${mapSection}

          <!-- RATING CTA -->
          <tr>
            <td style="padding:0 32px 28px;">
              <table width="100%" cellpadding="0" cellspacing="0"
                style="background:#fff8f8; border:1px solid #fecaca; border-radius:8px;">
                <tr>
                  <td style="padding:18px 20px;">
                    <p style="margin:0 0 4px; font-size:14px; font-weight:600; color:#111827;">
                      O que você achou do passeio?
                    </p>
                    <p style="margin:0; font-size:13px; color:#6b7280; line-height:1.6;">
                      Sua avaliação ajuda outros tutores a encontrar os melhores passeadores.
                      Abra o aplicativo PetTrail e deixe sua opinião sobre o passeio de
                      <strong>${data.walkerName}</strong>.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- FOOTER -->
          <tr>
            <td style="padding:20px 32px 28px; border-top:1px solid #f3f4f6;">
              <p style="margin:0 0 6px; font-size:11px; color:#9ca3af; text-align:center; line-height:1.7;">
                Você recebeu este email porque realizou um passeio na plataforma <strong>PetTrail</strong>.
              </p>
              <p style="margin:0; font-size:11px; color:#9ca3af; text-align:center; line-height:1.7;">
                Dúvidas ou problemas? Entre em contato com nosso suporte pelo aplicativo.
              </p>
              <p style="margin:12px 0 0; font-size:10px; color:#d1d5db; text-align:center;">
                © 2026 PetTrail · Todos os direitos reservados
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}
