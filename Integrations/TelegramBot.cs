using System.Net.Http;

namespace Radar.Integrations;

public class TelegramBot
{
    private readonly string _botToken = Environment.GetEnvironmentVariable("BOT_TOKEN")!;
    private readonly string _chatId = Environment.GetEnvironmentVariable("CHAT_ID")!;

    public async Task EnviarMensagemAsync(string mensagem)
    {
        var url = $"https://api.telegram.org/bot{_botToken}/sendMessage";
        using var client = new HttpClient();

        var content = new FormUrlEncodedContent(new[]
        {
            new KeyValuePair<string, string>("chat_id", _chatId),
            new KeyValuePair<string, string>("text", mensagem)
        });

        var response = await client.PostAsync(url, content);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            Console.WriteLine($"Erro ao enviar mensagem: {error}");
        }
    }
}
