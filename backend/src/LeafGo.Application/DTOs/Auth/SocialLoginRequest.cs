using System.ComponentModel.DataAnnotations;

namespace LeafGo.Application.DTOs.Auth
{
    public class SocialLoginRequest
    {
        [Required(ErrorMessage = "Provider is required")]
        [RegularExpression("^(Google|Facebook)$", ErrorMessage = "Provider must be Google or Facebook")]
        public string Provider { get; set; } = string.Empty;

        [Required(ErrorMessage = "Token is required")]
        public string Token { get; set; } = string.Empty;
    }
}
