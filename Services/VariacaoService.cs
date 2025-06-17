using Radar.Models;

namespace Radar.Services;

public class VariacaoService
{
    private const decimal LimitePercentual = 1.5m;

    public bool DeveDispararAlerta(Acao acao)
    {
        return Math.Abs(acao.VariacaoPercentual) >= LimitePercentual;
    }
}
