namespace Radar.Models;

public class Acao
{
    public string Ticker { get; set; } = "";
    public decimal CotacaoAtual { get; set; }
    public decimal CotacaoAnterior { get; set; }
    public decimal VariacaoPercentual => CotacaoAnterior == 0 ? 0 : ((CotacaoAtual - CotacaoAnterior) / CotacaoAnterior) * 100;
}
