using System;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using LeafGo.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace LeafGo.Infrastructure.Services
{
    public class FacebookAuthProvider : ISocialAuthProvider
    {
        private readonly HttpClient _httpClient;
        private readonly string _appId;
        private readonly string _appSecret;
        private readonly ILogger<FacebookAuthProvider> _logger;

        public FacebookAuthProvider(
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration,
            ILogger<FacebookAuthProvider> logger)
        {
            _httpClient = httpClientFactory.CreateClient();
            _appId = configuration["Authentication:Facebook:AppId"]
                ?? throw new InvalidOperationException("Facebook AppId not configured");
            _appSecret = configuration["Authentication:Facebook:AppSecret"]
                ?? throw new InvalidOperationException("Facebook AppSecret not configured");
            _logger = logger;
        }

        public async Task<SocialUserInfo> ValidateTokenAsync(string token)
        {
            try
            {
                // Step 1: Verify token is valid and belongs to our app
                var verifyUrl = $"https://graph.facebook.com/debug_token?input_token={token}&access_token={_appId}|{_appSecret}";
                var verifyResponse = await _httpClient.GetAsync(verifyUrl);
                var verifyJson = await verifyResponse.Content.ReadAsStringAsync();
                var verifyData = JsonDocument.Parse(verifyJson);

                var data = verifyData.RootElement.GetProperty("data");
                if (!data.GetProperty("is_valid").GetBoolean())
                {
                    throw new UnauthorizedAccessException("Invalid Facebook token");
                }

                var appId = data.GetProperty("app_id").GetString();
                if (appId != _appId)
                {
                    throw new UnauthorizedAccessException("Token does not belong to this app");
                }

                // Step 2: Get user info
                var userUrl = $"https://graph.facebook.com/me?fields=id,name,email,picture.type(large)&access_token={token}";
                var userResponse = await _httpClient.GetAsync(userUrl);
                var userJson = await userResponse.Content.ReadAsStringAsync();
                var userData = JsonDocument.Parse(userJson);
                var root = userData.RootElement;

                string? avatarUrl = null;
                if (root.TryGetProperty("picture", out var picture) &&
                    picture.TryGetProperty("data", out var pictureData) &&
                    pictureData.TryGetProperty("url", out var url))
                {
                    avatarUrl = url.GetString();
                }

                return new SocialUserInfo
                {
                    ProviderId = root.GetProperty("id").GetString() ?? "",
                    Email = root.TryGetProperty("email", out var email) ? email.GetString() ?? "" : "",
                    FullName = root.TryGetProperty("name", out var name) ? name.GetString() ?? "" : "",
                    AvatarUrl = avatarUrl
                };
            }
            catch (UnauthorizedAccessException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to validate Facebook token");
                throw new UnauthorizedAccessException("Invalid Facebook token");
            }
        }
    }
}
