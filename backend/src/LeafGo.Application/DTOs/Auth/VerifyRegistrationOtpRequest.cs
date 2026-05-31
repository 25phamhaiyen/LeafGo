namespace LeafGo.Application.DTOs.Auth
{
    public class VerifyRegistrationOtpRequest
    {
        public string Email { get; set; } = string.Empty;
        public string OtpCode { get; set; } = string.Empty;
    }
}
