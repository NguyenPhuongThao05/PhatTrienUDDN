# Spring Boot KeyCloak SSO Application

Ứng dụng Spring Boot tích hợp Single Sign-On (SSO) với KeyCloak sử dụng giao thức OIDC (OpenID Connect).

## Tính năng chính

- ✅ **OIDC Authentication** với KeyCloak
- ✅ **ID Token** và **Access Token** 
- ✅ **Refresh Token** hỗ trợ
- ✅ **Single Sign-On (SSO)**
- ✅ **Single Logout (SLO)**
- ✅ **API Endpoints** để truy xuất thông tin token và user
- ✅ **Bootstrap UI** đẹp mắt và responsive

## Cấu trúc dự án

```
src/
├── main/
│   ├── java/com/example/demo/
│   │   ├── config/
│   │   │   └── SecurityConfig.java          # Cấu hình Spring Security
│   │   ├── controller/
│   │   │   └── AuthController.java          # Controller xử lý authentication
│   │   ├── service/
│   │   │   └── TokenService.java            # Service xử lý token management
│   │   └── DemoApplication.java             # Main application class
│   └── resources/
│       ├── templates/
│       │   ├── index.html                   # Trang chủ
│       │   └── profile.html                 # Trang profile
│       └── application.properties           # Cấu hình ứng dụng
```

## Yêu cầu hệ thống

- Java 17+
- Maven 3.6+
- KeyCloak Server

## Cài đặt và Cấu hình

### 1. Cài đặt KeyCloak Server

#### Option 1: Sử dụng Docker (Khuyến nghị)

```bash
# Tải và chạy KeyCloak với Docker
docker run -p 8180:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  quay.io/keycloak/keycloak:latest start-dev
```

#### Option 2: Tải về và cài đặt thủ công

1. Tải KeyCloak từ [https://www.keycloak.org/downloads](https://www.keycloak.org/downloads)
2. Giải nén và chạy:
   ```bash
   cd keycloak-xx.x.x/bin
   ./kc.sh start-dev --http-port=8180
   ```

### 2. Cấu hình KeyCloak

1. **Truy cập KeyCloak Admin Console:**
   - URL: http://localhost:8180
   - Username: admin
   - Password: admin

2. **Tạo Realm (hoặc sử dụng master realm):**
   - Click "Create Realm" (nếu muốn tạo realm mới)
   - Hoặc sử dụng realm "master" có sẵn

3. **Tạo Client:**
   - Vào **Clients** → **Create client**
   - **Client ID:** `spring-boot-app`
   - **Client Type:** OpenID Connect
   - **Next** → **Next**
   - **Save**

4. **Cấu hình Client:**
   - **Settings tab:**
     - **Access Type:** confidential
     - **Valid Redirect URIs:** `http://localhost:8080/login/oauth2/code/keycloak`
     - **Valid Post Logout Redirect URIs:** `http://localhost:8080/`
     - **Web Origins:** `http://localhost:8080`
   - **Credentials tab:**
     - Copy **Secret** (để cập nhật vào application.properties)

5. **Tạo User:**
   - Vào **Users** → **Add user**
   - Điền thông tin: Username, Email, First Name, Last Name
   - **Save**
   - Vào tab **Credentials** → Set password và tắt "Temporary"

### 3. Cấu hình Spring Boot Application

Cập nhật file `src/main/resources/application.properties`:

```properties
# KeyCloak OIDC Configuration
spring.security.oauth2.client.registration.keycloak.client-id=spring-boot-app
spring.security.oauth2.client.registration.keycloak.client-secret=YOUR_CLIENT_SECRET_HERE
spring.security.oauth2.client.registration.keycloak.scope=openid,profile,email,offline_access
spring.security.oauth2.client.registration.keycloak.authorization-grant-type=authorization_code
spring.security.oauth2.client.registration.keycloak.redirect-uri={baseUrl}/login/oauth2/code/{registrationId}

# KeyCloak Provider Configuration  
spring.security.oauth2.client.provider.keycloak.issuer-uri=http://localhost:8180/realms/master
spring.security.oauth2.client.provider.keycloak.user-name-attribute=preferred_username
```

**Lưu ý quan trọng:**
- Thay `YOUR_CLIENT_SECRET_HERE` bằng client secret từ KeyCloak
- Nếu sử dụng realm khác thay `master` trong issuer-uri
- Cổng KeyCloak mặc định là 8180 để tránh xung đột với Spring Boot (8080)

## Chạy ứng dụng

1. **Build và chạy:**
   ```bash
   ./mvnw spring-boot:run
   ```

2. **Truy cập ứng dụng:**
   - URL: http://localhost:8080
   - Click "Đăng nhập với KeyCloak"
   - Đăng nhập bằng user đã tạo trong KeyCloak

## API Endpoints

| Endpoint | Mô tả |
|----------|-------|
| `GET /` | Trang chủ |
| `GET /profile` | Trang profile user |
| `GET /login` | Redirect đến KeyCloak login |
| `GET /logout` | Đăng xuất và logout từ KeyCloak |
| `GET /api/user` | API trả về thông tin user (JSON) |
| `GET /api/token` | API trả về ID token info (JSON) |
| `GET /api/tokens` | API trả về tất cả token info (JSON) |
| `GET /api/refresh-token` | API trả về refresh token info (JSON) |

## Kiểm tra Token

### ID Token Claims
Khi đăng nhập thành công, bạn có thể xem các claims trong ID Token tại trang `/profile`:
- `sub`: Subject identifier
- `preferred_username`: Username
- `email`: Email address
- `name`: Full name
- `iat`: Issued at time
- `exp`: Expiration time
- Và nhiều claims khác...

### Access Token và Refresh Token
- **Access Token**: Dùng để authorize API calls
- **Refresh Token**: Dùng để làm mới access token khi hết hạn
- Scope `offline_access` cần thiết để nhận refresh token

## Troubleshooting

### Lỗi thường gặp:

1. **"Invalid redirect_uri"**
   - Kiểm tra Valid Redirect URIs trong KeyCloak client settings
   - Đảm bảo URL chính xác: `http://localhost:8080/login/oauth2/code/keycloak`

2. **"Invalid client credentials"**
   - Kiểm tra client-secret trong application.properties
   - Đảm bảo client-id chính xác

3. **"Issuer validation failed"**
   - Kiểm tra issuer-uri trong application.properties
   - Đảm bảo KeyCloak server đang chạy và accessible

4. **Token không có refresh token**
   - Đảm bảo scope có `offline_access`
   - Kiểm tra KeyCloak client settings cho phép offline access

### Debug
Enable debug logging trong application.properties:
```properties
logging.level.org.springframework.security=DEBUG
logging.level.org.springframework.security.oauth2=DEBUG
```

## Cấu hình Production

Trong môi trường production:

1. **Sử dụng HTTPS:**
   ```properties
   spring.security.oauth2.client.registration.keycloak.redirect-uri=https://your-domain.com/login/oauth2/code/keycloak
   spring.security.oauth2.client.provider.keycloak.issuer-uri=https://your-keycloak-domain.com/realms/your-realm
   ```

2. **Bảo mật client secret:**
   - Sử dụng environment variables
   - Hoặc external configuration management

3. **Cấu hình KeyCloak:**
   - Sử dụng database thay vì H2
   - Setup cluster cho high availability
   - Cấu hình SSL/TLS

## Dependencies

```xml
<!-- Spring Boot Starters -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-client</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>
<dependency>
    <groupId>org.thymeleaf.extras</groupId>
    <artifactId>thymeleaf-extras-springsecurity6</artifactId>
</dependency>
```

## Tác giả

Dự án demo Spring Boot KeyCloak SSO với OIDC và Refresh Token support.

## License

MIT License