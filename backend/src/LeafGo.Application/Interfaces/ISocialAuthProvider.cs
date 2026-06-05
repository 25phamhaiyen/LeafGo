using System.Threading.Tasks;

namespace LeafGo.Application.Interfaces
{
    public interface ISocialAuthProvider
    {
        Task<SocialUserInfo> ValidateTokenAsync(string token);
    }

    public class SocialUserInfo
    {
        public string ProviderId { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? AvatarUrl { get; set; }
    }
}
