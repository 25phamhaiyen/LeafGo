using LeafGo.Application.DTOs.Auth;
using LeafGo.Application.Interfaces;
using LeafGo.Domain.Constants;
using LeafGo.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace LeafGo.Infrastructure.Services
{
    public class AuthService : IAuthService
    {
        private readonly LeafGoDbContext _context;
        private readonly IJwtService _jwtService;
        private readonly IPasswordHasher _passwordHasher;
        private readonly IEmailService _emailService;
        private readonly IMemoryCache _cache;

        public AuthService(
            LeafGoDbContext context,
            IJwtService jwtService,
            IPasswordHasher passwordHasher,
            IEmailService emailService,
            IMemoryCache cache)
        {
            _context = context;
            _jwtService = jwtService;
            _passwordHasher = passwordHasher;
            _emailService = emailService;
            _cache = cache;
        }

        public async Task RequestRegistrationOtpAsync(RegisterRequest request)
        {
            // Check if email already exists
            var existingUser = await _context.Set<User>()
                .FirstOrDefaultAsync(u => u.Email == request.Email);

            if (existingUser != null)
            {
                throw new InvalidOperationException("Email already exists");
            }

            // Validate role
            if (request.Role != UserRoles.User && request.Role != UserRoles.Driver)
            {
                throw new InvalidOperationException("Invalid role. Must be User or Driver");
            }

            // Generate 6-digit OTP
            var otp = new Random().Next(100000, 999999).ToString();

            // Cache the request and OTP for 5 minutes
            var cacheKey = $"Reg_{request.Email}";
            _cache.Set(cacheKey, new { Request = request, Otp = otp }, TimeSpan.FromMinutes(5));

            // Send OTP email
            await _emailService.SendRegistrationOtpEmailAsync(request.Email, otp);
        }

        public async Task<AuthResponse> VerifyRegistrationOtpAsync(VerifyRegistrationOtpRequest request, string? ipAddress)
        {
            var cacheKey = $"Reg_{request.Email}";
            if (!_cache.TryGetValue(cacheKey, out dynamic? cachedData) || cachedData == null)
            {
                throw new InvalidOperationException("OTP has expired or was not requested");
            }

            string cachedOtp = cachedData.Otp;
            RegisterRequest regRequest = cachedData.Request;

            if (cachedOtp != request.OtpCode)
            {
                throw new InvalidOperationException("Invalid OTP code");
            }

            // Create new user
            var user = new User
            {
                Id = Guid.NewGuid(),
                Email = regRequest.Email,
                PasswordHash = _passwordHasher.HashPassword(regRequest.Password),
                FullName = regRequest.FullName,
                PhoneNumber = regRequest.PhoneNumber,
                Role = regRequest.Role,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Set<User>().Add(user);
            await _context.SaveChangesAsync();

            // Clear cache
            _cache.Remove(cacheKey);

            // Generate tokens
            var accessToken = _jwtService.GenerateAccessToken(user);
            var refreshToken = _jwtService.GenerateRefreshToken();

            // Save refresh token
            await SaveRefreshTokenAsync(user.Id, refreshToken, ipAddress);

            // Send welcome email (fire and forget)
            _ = _emailService.SendWelcomeEmailAsync(user.Email, user.FullName);

            return new AuthResponse
            {
                Id = user.Id,
                Email = user.Email,
                FullName = user.FullName,
                Role = user.Role,
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                ExpiresAt = DateTime.UtcNow.AddMinutes(15),
                IsOnline = user.IsOnline
            };
        }

        public async Task<AuthResponse> LoginAsync(LoginRequest request, string? ipAddress)
        {
            // Find user by email
            var user = await _context.Set<User>()
                .FirstOrDefaultAsync(u => u.Email == request.Email && !u.IsDeleted);

            if (user == null)
            {
                throw new UnauthorizedAccessException("Invalid email or password");
            }

            // Verify password
            if (!_passwordHasher.VerifyPassword(request.Password, user.PasswordHash))
            {
                throw new UnauthorizedAccessException("Invalid email or password");
            }

            // Check if account is active
            if (!user.IsActive)
            {
                throw new UnauthorizedAccessException("Account is locked. Please contact administrator");
            }

            // Generate tokens
            var accessToken = _jwtService.GenerateAccessToken(user);
            var refreshToken = _jwtService.GenerateRefreshToken();

            // Save refresh token
            await SaveRefreshTokenAsync(user.Id, refreshToken, ipAddress);

            return new AuthResponse
            {
                Id = user.Id,
                Email = user.Email,
                FullName = user.FullName,
                Role = user.Role,
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                ExpiresAt = DateTime.UtcNow.AddMinutes(15),
                IsOnline = user.IsOnline
            };
        }

        public async Task<RefreshTokenResponse> RefreshTokenAsync(string token, string? ipAddress)
        {
            var refreshToken = await _context.Set<RefreshToken>()
                .Include(rt => rt.User)
                .FirstOrDefaultAsync(rt => rt.Token == token);

            if (refreshToken == null)
            {
                throw new UnauthorizedAccessException("Invalid refresh token");
            }

            if (!refreshToken.IsActive)
            {
                throw new UnauthorizedAccessException("Invalid or expired refresh token");
            }

            // Check if user is still active
            if (!refreshToken.User.IsActive || refreshToken.User.IsDeleted)
            {
                throw new UnauthorizedAccessException("User account is not active");
            }

            // Generate new tokens
            var newAccessToken = _jwtService.GenerateAccessToken(refreshToken.User);
            var newRefreshToken = _jwtService.GenerateRefreshToken();

            // Revoke old token and save new one
            refreshToken.RevokedAt = DateTime.UtcNow;
            refreshToken.RevokedByIp = ipAddress;
            refreshToken.ReplacedByToken = newRefreshToken;

            await SaveRefreshTokenAsync(refreshToken.UserId, newRefreshToken, ipAddress);
            await _context.SaveChangesAsync();

            return new RefreshTokenResponse
            {
                AccessToken = newAccessToken,
                RefreshToken = newRefreshToken,
                ExpiresAt = DateTime.UtcNow.AddMinutes(15)
            };
        }

        public async Task RevokeTokenAsync(string token, string? ipAddress)
        {
            var refreshToken = await _context.Set<RefreshToken>()
                .FirstOrDefaultAsync(rt => rt.Token == token);

            if (refreshToken == null || !refreshToken.IsActive)
            {
                throw new InvalidOperationException("Invalid refresh token");
            }

            refreshToken.RevokedAt = DateTime.UtcNow;
            refreshToken.RevokedByIp = ipAddress;

            await _context.SaveChangesAsync();
        }

        public async Task RevokeAllTokensAsync(Guid userId, string? ipAddress)
        {
            var activeTokens = await _context.Set<RefreshToken>()
                .Where(rt => rt.UserId == userId && rt.RevokedAt == null && rt.ExpiresAt > DateTime.UtcNow)
                .ToListAsync();

            foreach (var token in activeTokens)
            {
                token.RevokedAt = DateTime.UtcNow;
                token.RevokedByIp = ipAddress;
            }

            await _context.SaveChangesAsync();
        }

        public async Task<IEnumerable<ActiveTokenResponse>> GetActiveTokensAsync(Guid userId)
        {
            var tokens = await _context.Set<RefreshToken>()
                .Where(rt => rt.UserId == userId && rt.RevokedAt == null && rt.ExpiresAt > DateTime.UtcNow)
                .OrderByDescending(rt => rt.CreatedAt)
                .Select(rt => new ActiveTokenResponse
                {
                    Id = rt.Id,
                    CreatedAt = rt.CreatedAt,
                    ExpiresAt = rt.ExpiresAt,
                    CreatedByIp = rt.CreatedByIp,
                    IsActive = rt.RevokedAt == null && rt.ExpiresAt > DateTime.UtcNow
                })
                .ToListAsync();

            return tokens;
        }

        public async Task ChangePasswordAsync(Guid userId, ChangePasswordRequest request)
        {
            var user = await _context.Set<User>()
                .FirstOrDefaultAsync(u => u.Id == userId && !u.IsDeleted);

            if (user == null)
            {
                throw new InvalidOperationException("User not found");
            }

            // Verify current password
            if (!_passwordHasher.VerifyPassword(request.CurrentPassword, user.PasswordHash))
            {
                throw new UnauthorizedAccessException("Current password is incorrect");
            }

            // Update password
            user.PasswordHash = _passwordHasher.HashPassword(request.NewPassword);
            user.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
        }

        public async Task ForgotPasswordAsync(ForgotPasswordRequest request)
        {
            var user = await _context.Set<User>()
                .FirstOrDefaultAsync(u => u.Email == request.Email && !u.IsDeleted);

            // Don't reveal if user exists or not
            if (user == null)
            {
                return;
            }

            // Generate 6-digit reset OTP
            var resetOtp = new Random().Next(100000, 999999).ToString();
            user.ResetPasswordToken = _passwordHasher.HashPassword(resetOtp); // Hash the OTP
            user.ResetPasswordExpiry = DateTime.UtcNow.AddMinutes(5); // 5 minutes expiry
            user.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            // Send reset OTP email
            await _emailService.SendPasswordResetEmailAsync(user.Email, resetOtp);
        }

        public async Task ResetPasswordAsync(ResetPasswordRequest request)
        {
            // Find user by email
            var user = await _context.Set<User>()
                .FirstOrDefaultAsync(u => u.Email == request.Email && !u.IsDeleted);

            if (user == null || user.ResetPasswordToken == null || user.ResetPasswordExpiry < DateTime.UtcNow)
            {
                throw new InvalidOperationException("Invalid or expired reset token");
            }

            // Verify OTP
            if (!_passwordHasher.VerifyPassword(request.Token, user.ResetPasswordToken))
            {
                throw new InvalidOperationException("Invalid OTP code");
            }

            // Update password and clear reset token
            user.PasswordHash = _passwordHasher.HashPassword(request.NewPassword);
            user.ResetPasswordToken = null;
            user.ResetPasswordExpiry = null;
            user.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
        }

        private async Task SaveRefreshTokenAsync(Guid userId, string token, string? ipAddress)
        {
            var refreshToken = new RefreshToken
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Token = token,
                ExpiresAt = DateTime.UtcNow.AddDays(7),
                CreatedAt = DateTime.UtcNow,
                CreatedByIp = ipAddress
            };

            _context.Set<RefreshToken>().Add(refreshToken);
            await _context.SaveChangesAsync();
        }
    }
}
