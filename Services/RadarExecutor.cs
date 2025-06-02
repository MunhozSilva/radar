namespace Radar.Services;

public class RadarExecutor
{
    private readonly CotacaoService _cotacaoService = new();
    private readonly AlertaService _alertaService = new();
    private readonly VariacaoService _variacaoService = new();

    public async Task ExecutarRadarAsync()
    {
        var tickers = new List<string> { "auren-energia-aure3", "caixa-seguridade-cxse3", "banco-do-brasil-bbas3" };

        foreach (var ticker in tickers)
        {
            var acao = await _cotacaoService.ObterCotacoesAsync(ticker);
            if (acao != null)
            {
                if (_variacaoService.DeveDispararAlerta(acao))
                {
                    await _alertaService.EnviarAlertaAsync(acao);
                }
            }
        }
    }
}
