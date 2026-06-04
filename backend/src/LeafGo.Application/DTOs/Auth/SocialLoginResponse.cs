namespace LeafGo.Application.DTOs.Auth
{
    public class SocialLoginResponse
    {
        public AuthResponse? AuthData { get; set; }
        public bool IsNewUser { get; set; }
        public string? Email { get; set; }
        public string? FullName { get; set; }
        public string? AvatarUrl { get; set; }
    }
}
