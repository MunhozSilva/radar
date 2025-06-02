using Radar.Models;
using Radar.Integrations;

namespace Radar.Services;

public class AlertaService
{
    private readonly TelegramBot _telegramBot = new();

    public async Task EnviarAlertaAsync(Acao acao)
    {
        var msg = $"⚠️ {acao.Ticker.Substring(acao.Ticker.LastIndexOf('-') + 1).ToUpper()} teve variação de {acao.VariacaoPercentual:F2}%\n" +
                  $"💰 Atual: R${acao.CotacaoAtual} | Ontem: R${acao.CotacaoAnterior}";
        await _telegramBot.EnviarMensagemAsync(msg);
    }
}
