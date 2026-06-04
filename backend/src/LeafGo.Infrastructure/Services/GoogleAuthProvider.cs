using Google.Apis.Auth;
using LeafGo.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace LeafGo.Infrastructure.Services
{
    public class GoogleAuthProvider : ISocialAuthProvider
    {
        private readonly string _clientId;
        private readonly ILogger<GoogleAuthProvider> _logger;

        public GoogleAuthProvider(IConfiguration configuration, ILogger<GoogleAuthProvider> logger)
        {
            _clientId = configuration["Authentication:Google:ClientId"]
                ?? throw new InvalidOperationException("Google ClientId not configured");
            _logger = logger;
        }

        public async Task<SocialUserInfo> ValidateTokenAsync(string token)
        {
            try
            {
                var settings = new GoogleJsonWebSignature.ValidationSettings
                {
                    Audience = new[] { _clientId }
                };

                var payload = await GoogleJsonWebSignature.ValidateAsync(token, settings);

                return new SocialUserInfo
                {
                    ProviderId = payload.Subject,
                    Email = payload.Email,
                    FullName = payload.Name ?? payload.Email,
                    AvatarUrl = payload.Picture
                };
            }
            catch (InvalidJwtException ex)
            {
                _logger.LogWarning(ex, "Invalid Google token");
                throw new UnauthorizedAccessException("Invalid Google token");
            }
        }
    }
}
