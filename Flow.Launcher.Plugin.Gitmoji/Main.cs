using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net.Http;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading;
using System.Threading.Tasks;
using System.Xml;
using Flow.Launcher.Plugin;

namespace Flow.Launcher.Plugin.Gitmoji;

public class Gitmoji : IAsyncPlugin
{
    private const string _apiUrl = "https://gitmoji.dev/api/gitmojis";
    private PluginInitContext _context;

    public async Task<List<Result>> QueryAsync(Query query, CancellationToken token)
    {
        var response = await _context.API.HttpGetStringAsync(_apiUrl + Uri.EscapeDataString(query.Search), token);
        var json = JsonSerializer.Deserialize<GitmojiResponse>(response);

        return json.Gitmojis.Select(g => new Result {
            Title = $"{g.Code} {g.Name}",
            SubTitle = g.Description,
            Action = _ => {
                _context.API.CopyToClipboard(g.Code);
                return true;
            },
            IcoPath = "app.png";
        }).ToList();
    }

    public async Task InitAsync(PluginInitContext context)
    {
        _context = context;
    }
}

public class GitmojiModel
{
    public string Name { get; set; }
    public string Code { get; set; }
    public string Emoji { get; set; }
    public string Description { get; set; }
}

public class GitmojiResponse
{
    public List<GitmojiModel> Gitmojis { get; set; }
}