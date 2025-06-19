using Radar.Models;

namespace Radar.Services;

public class VariacaoService
{
    private const decimal LimitePercentual = 2.0m;

    public bool DeveDispararAlerta(Acao acao)
    {
        return Math.Abs(acao.VariacaoPercentual) >= LimitePercentual;
    }
}
