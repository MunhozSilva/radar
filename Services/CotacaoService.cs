using OpenQA.Selenium;
using OpenQA.Selenium.Chrome;
using Radar.Models;
using System.Globalization;

public class CotacaoService
{
    public async Task<Acao?> ObterCotacoesAsync(string ticker)
    {
        var options = new ChromeOptions();
        options.AddArgument("--headless=new");
        options.AddArgument("--disable-gpu");
        options.AddArgument("--no-sandbox");

        var service = ChromeDriverService.CreateDefaultService("/usr/local/bin");
        service.HideCommandPromptWindow = true;

        using var driver = new ChromeDriver(service, options);

        try
        {
            var url = $"https://www.infomoney.com.br/cotacoes/b3/acao/{ticker}/";
            driver.Navigate().GoToUrl(url);
            await Task.Delay(2000);

            // Cotação atual
            var cotacaoAtualElemento = driver.FindElement(By.CssSelector(
                "body > div.fill-lightgray.border-b > div > div.row > div.col-12.col-lg-8.order-2.order-lg-1 > div > div.line-info > div.value > p"));
            var cotacaoAtualTexto = cotacaoAtualElemento.Text.Replace("R$", "").Replace(",", ".").Trim();
            var cotacaoAtual = decimal.Parse(cotacaoAtualTexto, CultureInfo.InvariantCulture);

            // Cotação anterior
            var cotacaoAnteriorElemento = driver.FindElement(By.CssSelector(
                "#header-quotes > div.tables > table:nth-child(1) > tbody > tr:nth-child(1) > td:nth-child(2)"));
            var cotacaoAnteriorTexto = cotacaoAnteriorElemento.Text.Replace("R$", "").Replace(",", ".").Trim();
            var cotacaoAnterior = decimal.Parse(cotacaoAnteriorTexto, CultureInfo.InvariantCulture);

            var acao = new Acao
            {
                Ticker = ticker,
                CotacaoAtual = cotacaoAtual,
                CotacaoAnterior = cotacaoAnterior
            };

            Console.WriteLine($"[{acao.Ticker}] Atual: {acao.CotacaoAtual} | Anterior: {acao.CotacaoAnterior} | Variação: {acao.VariacaoPercentual:F2}%");

            return acao;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Erro ao obter cotações para {ticker}: {ex.Message}");
            return null;
        }
        finally
        {
            driver.Quit();
        }
    }
}
