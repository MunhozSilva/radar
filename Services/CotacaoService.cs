using HtmlAgilityPack;
using Radar.Models;
using System.Globalization;

public class CotacaoService
{
    private readonly HttpClient _httpClient;

    public CotacaoService()
    {
        _httpClient = new HttpClient();
    }

    public async Task<Acao?> ObterCotacoesAsync(string ticker)
    {
        try
        {
            var url = $"https://www.infomoney.com.br/cotacoes/b3/acao/{ticker}/";
            var html = await _httpClient.GetStringAsync(url);

            var htmlDoc = new HtmlDocument();
            htmlDoc.LoadHtml(html);

            var cotacaoAtualNode = htmlDoc.DocumentNode.SelectSingleNode("//div[contains(@class,'line-info')]//div[contains(@class,'value')]//p");
            if (cotacaoAtualNode == null)
                throw new Exception("Elemento de cotação atual não encontrado");

            var cotacaoAtualTexto = cotacaoAtualNode.InnerText.Replace("R$", "").Replace(".", "").Replace(",", ".").Trim();
            var cotacaoAtual = decimal.Parse(cotacaoAtualTexto, CultureInfo.InvariantCulture);

            var cotacaoAnteriorNode = htmlDoc.DocumentNode.SelectSingleNode("//div[@id='header-quotes']//table[1]//tr[1]/td[2]");
            if (cotacaoAnteriorNode == null)
                throw new Exception("Elemento de cotação anterior não encontrado");

            var cotacaoAnteriorTexto = cotacaoAnteriorNode.InnerText.Replace("R$", "").Replace(".", "").Replace(",", ".").Trim();
            var cotacaoAnterior = decimal.Parse(cotacaoAnteriorTexto, CultureInfo.InvariantCulture);

            var acao = new Acao
            {
                Ticker = ticker,
                CotacaoAtual = cotacaoAtual,
                CotacaoAnterior = cotacaoAnterior
            };

            Console.WriteLine($"[{acao.Ticker}] Atual: {acao.CotacaoAtual} | Anterior: {acao.CotacaoAnterior}");

            return acao;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Erro ao obter cotações para {ticker}: {ex.Message}");
            return null;
        }
    }
}
