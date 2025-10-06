package be.pxl.bookapplication.api;


import be.pxl.bookapplication.Exception.EmailAlreadyExistsException;
import be.pxl.bookapplication.Exception.NotFoundException;
import be.pxl.bookapplication.config.JwtUtil;
import be.pxl.bookapplication.domain.MyUserPrincipal;
import be.pxl.bookapplication.domain.User;
import be.pxl.bookapplication.domain.UserDetails;
import be.pxl.bookapplication.repository.UserRepository;
import be.pxl.bookapplication.request.LoginRequest;
import be.pxl.bookapplication.request.updateUserTestingRequest;
import be.pxl.bookapplication.service.UserDetailsService;
import be.pxl.bookapplication.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;


@RestController
@RequestMapping("/api/auth")
public class UserController {
    //properties
    private final UserService userService;
    private final UserRepository userRepository;
    private final UserDetailsService userDetailsService;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;

    @Autowired
    public UserController(
        UserService userService,
        UserRepository userRepository,
        UserDetailsService userDetailsService,
        JwtUtil jwtUtil,
        AuthenticationManager authenticationManager
    ) {
        this.userService = userService;
        this.userRepository = userRepository;
        this.userDetailsService = userDetailsService;
        this.jwtUtil = jwtUtil;
        this.authenticationManager = authenticationManager;
    }

    private String getCookieDomain(HttpServletRequest request) {
        String host = request.getHeader("Host");
        if (host != null) {
            // Extract domain from host (remove port if present)
            String domain = host.split(":")[0];
            // For localhost, return null (browser will use current domain)
            if ("localhost".equals(domain) || "127.0.0.1".equals(domain)) {
                return null;
            }
            return domain;
        }
        return null;
    }


    @GetMapping("/check-cookie")
    public ResponseEntity<?> checkHttpOnlyCookie(HttpServletRequest request) {
        if (request.getCookies() != null) {
            for (var cookie : request.getCookies()) {
                if ("JWT".equals(cookie.getName())) {
                    return ResponseEntity.ok(Map.of("message", "Cookie found"));
                }
            }
        }
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "No valid cookie found"));
    }


    @PostMapping("/users")
    public ResponseEntity<?> addUser(@RequestBody User user, HttpServletRequest request) {
        if (userRepository.existsByEmail(user.getEmail())) {
            throw new EmailAlreadyExistsException("Email already exists");
        }

        User saveduser = userService.RegisterUser(user);
        userDetailsService.updateUserDetails(saveduser.getId());

        String token = jwtUtil.generateToken(saveduser.getEmail());

        ResponseCookie cookie = ResponseCookie.from("JWT", token)
            .httpOnly(true)
            .secure(false)
            .path("/")
            .maxAge(86400)
            .sameSite("Lax")  // Change from Strict to Lax for cross-origin
            .domain(getCookieDomain(request))  // Dynamic domain
            .build();

        return ResponseEntity.ok()
            .header(HttpHeaders.SET_COOKIE, cookie.toString())
            .body(Map.of(
                "email", saveduser.getEmail(),
                "success", true
            ));
    }


    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request, HttpServletRequest httpRequest) {
        try {
            // Authenticate using email (from User entity) and password
            authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                    request.getEmail(),
                    request.getPassword()
                )
            );

            // Fetch User entity (contains email)
            User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new NotFoundException("User not found"));

            // Generate JWT token with email
            String token = jwtUtil.generateToken(user.getEmail());

            // Set JWT as an HTTP-only cookie
            ResponseCookie cookie = ResponseCookie.from("JWT", token)
                .httpOnly(true)
                .secure(false) // Set to `true` in production
                .path("/")
                .maxAge(86400) // 24 hours
                .sameSite("Lax")
                .domain(getCookieDomain(httpRequest))
                .build();

            return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, cookie.toString())
                .body(Map.of(
                    "email", user.getEmail(),
                    "message", "Login successful"
                ));

        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("message", "Invalid credentials"));
        }
    }




}
