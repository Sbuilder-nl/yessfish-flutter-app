# YessFish REST API Specification

## Base URL
```
https://yessfish.com/api/v1
```

## Authentication
- **Method**: JWT (JSON Web Tokens)
- **Header**: `Authorization: Bearer <token>`
- **Token Expiry**: 30 days
- **Refresh Token**: 90 days

## API Endpoints

### 1. Authentication

#### POST `/auth/login`
**Description**: Login user with email and password

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "name": "Richard Sip",
      "email": "richard@example.com",
      "profile_photo": "https://yessfish.com/uploads/profiles/user1.jpg",
      "is_admin": 0,
      "created_at": "2024-01-15T10:30:00Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "dGhpcyBpcyBhIHJlZnJl..."
  }
}
```

#### POST `/auth/register`
**Description**: Register new user

**Request Body**:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "city": "Amsterdam",
  "country": "Nederland"
}
```

**Response Success (201)**:
```json
{
  "success": true,
  "message": "Registration successful. Please check your email to verify your account.",
  "data": {
    "user": {
      "id": 123,
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
}
```

#### POST `/auth/logout`
**Description**: Logout user (invalidate token)

**Response Success (200)**:
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

#### POST `/auth/refresh`
**Description**: Refresh access token

**Request Body**:
```json
{
  "refresh_token": "dGhpcyBpcyBhIHJlZnJl..."
}
```

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "bmV3IHJlZnJlc2ggdG9r..."
  }
}
```

---

### 2. User Profile

#### GET `/user/profile`
**Description**: Get current user's profile

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Richard Sip",
    "email": "richard@example.com",
    "profile_photo": "https://yessfish.com/uploads/profiles/user1.jpg",
    "city": "Groningen",
    "country": "Nederland",
    "bio": "Passionate angler from Groningen",
    "is_admin": 0,
    "stats": {
      "catches": 42,
      "posts": 15,
      "friends": 28,
      "albums": 5
    },
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

#### GET `/user/profile/{user_id}`
**Description**: Get another user's profile

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "id": 2,
    "name": "Erik van Dijk",
    "profile_photo": "https://yessfish.com/uploads/profiles/user2.jpg",
    "city": "Amsterdam",
    "country": "Nederland",
    "bio": "Love fishing on weekends",
    "stats": {
      "catches": 38,
      "posts": 12,
      "friends": 19,
      "albums": 3
    },
    "recent_catches": [...],
    "recent_posts": [...],
    "is_friend": false,
    "friend_request_sent": false
  }
}
```

#### PUT `/user/profile`
**Description**: Update current user's profile

**Request Body**:
```json
{
  "name": "Richard Sip Updated",
  "city": "Groningen",
  "country": "Nederland",
  "bio": "Updated bio text",
  "profile_photo": "base64_encoded_image_or_url"
}
```

---

### 3. Posts

#### GET `/posts`
**Description**: Get paginated list of public posts

**Query Parameters**:
- `page` (int, default: 1)
- `limit` (int, default: 20, max: 50)
- `user_id` (int, optional) - Filter by user
- `sort` (string, default: "recent") - Options: recent, popular, trending

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "posts": [
      {
        "id": 123,
        "user_id": 1,
        "user_name": "Richard Sip",
        "user_photo": "https://yessfish.com/uploads/profiles/user1.jpg",
        "title": "Amazing catch today!",
        "content": "Caught a 5kg carp at Lake Groningen...",
        "image": "https://yessfish.com/uploads/posts/post123.jpg",
        "is_public": 1,
        "like_count": 24,
        "comment_count": 8,
        "is_liked": false,
        "created_at": "2025-10-17T14:30:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 10,
      "total_items": 198,
      "per_page": 20,
      "has_more": true
    }
  }
}
```

#### GET `/posts/{post_id}`
**Description**: Get single post with full details and comments

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "id": 123,
    "user_id": 1,
    "user_name": "Richard Sip",
    "user_photo": "https://yessfish.com/uploads/profiles/user1.jpg",
    "title": "Amazing catch today!",
    "content": "Full content of the post...",
    "image": "https://yessfish.com/uploads/posts/post123.jpg",
    "is_public": 1,
    "like_count": 24,
    "comment_count": 8,
    "is_liked": false,
    "created_at": "2025-10-17T14:30:00Z",
    "comments": [
      {
        "id": 456,
        "user_id": 2,
        "user_name": "Erik van Dijk",
        "user_photo": "https://yessfish.com/uploads/profiles/user2.jpg",
        "content": "Great catch! What bait did you use?",
        "created_at": "2025-10-17T15:00:00Z"
      }
    ]
  }
}
```

#### POST `/posts`
**Description**: Create new post

**Request Body**:
```json
{
  "title": "My amazing fishing trip",
  "content": "Today I went fishing at...",
  "image": "base64_encoded_image_or_url",
  "is_public": 1
}
```

**Response Success (201)**:
```json
{
  "success": true,
  "message": "Post created successfully",
  "data": {
    "id": 124,
    "title": "My amazing fishing trip",
    "created_at": "2025-10-17T16:00:00Z"
  }
}
```

#### PUT `/posts/{post_id}`
**Description**: Update own post

#### DELETE `/posts/{post_id}`
**Description**: Delete own post

---

### 4. Comments

#### POST `/posts/{post_id}/comments`
**Description**: Add comment to post

**Request Body**:
```json
{
  "content": "Great catch! What bait did you use?"
}
```

#### GET `/posts/{post_id}/comments`
**Description**: Get all comments for a post

#### DELETE `/comments/{comment_id}`
**Description**: Delete own comment

---

### 5. Likes

#### POST `/posts/{post_id}/like`
**Description**: Like a post

**Response Success (200)**:
```json
{
  "success": true,
  "message": "Post liked",
  "data": {
    "like_count": 25
  }
}
```

#### DELETE `/posts/{post_id}/like`
**Description**: Unlike a post

---

### 6. Catches (Vangsten)

#### GET `/catches`
**Description**: Get paginated list of catches

**Query Parameters**:
- `page` (int, default: 1)
- `limit` (int, default: 20)
- `user_id` (int, optional)
- `fish_type` (string, optional)

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "catches": [
      {
        "id": 789,
        "user_id": 1,
        "user_name": "Richard Sip",
        "fish_type": "Carp",
        "weight": 5.2,
        "length": 45,
        "location": "Lake Groningen",
        "latitude": 53.2194,
        "longitude": 6.5665,
        "photo": "https://yessfish.com/uploads/catches/catch789.jpg",
        "bait_used": "Boilies",
        "weather": "Sunny, 22°C",
        "catch_date": "2025-10-17T08:30:00Z",
        "created_at": "2025-10-17T10:00:00Z"
      }
    ],
    "pagination": {...}
  }
}
```

#### POST `/catches`
**Description**: Log new catch

**Request Body**:
```json
{
  "fish_type": "Carp",
  "weight": 5.2,
  "length": 45,
  "location": "Lake Groningen",
  "latitude": 53.2194,
  "longitude": 6.5665,
  "photo": "base64_encoded_image",
  "bait_used": "Boilies",
  "catch_date": "2025-10-17T08:30:00Z"
}
```

---

### 7. Friends

#### GET `/friends`
**Description**: Get user's friends list

#### GET `/friends/requests`
**Description**: Get pending friend requests

#### POST `/friends/request/{user_id}`
**Description**: Send friend request

#### POST `/friends/accept/{request_id}`
**Description**: Accept friend request

#### POST `/friends/decline/{request_id}`
**Description**: Decline friend request

#### DELETE `/friends/{user_id}`
**Description**: Remove friend

---

### 8. Fishing Spots

#### GET `/spots`
**Description**: Get list of fishing spots

**Query Parameters**:
- `latitude` (float, optional)
- `longitude` (float, optional)
- `radius` (int, default: 50km)

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "spots": [
      {
        "id": 456,
        "name": "Lake Groningen",
        "description": "Great spot for carp fishing",
        "latitude": 53.2194,
        "longitude": 6.5665,
        "rating": 4.5,
        "photo": "https://yessfish.com/uploads/spots/spot456.jpg",
        "added_by": {
          "id": 1,
          "name": "Richard Sip"
        },
        "fish_types": ["Carp", "Pike", "Perch"],
        "facilities": ["Parking", "Toilets", "Fishing platforms"],
        "created_at": "2024-08-10T12:00:00Z"
      }
    ]
  }
}
```

#### POST `/spots`
**Description**: Add new fishing spot

---

### 9. Notifications

#### GET `/notifications`
**Description**: Get user's notifications

**Query Parameters**:
- `unread_only` (bool, default: false)
- `page` (int, default: 1)
- `limit` (int, default: 20)

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": 999,
        "type": "friend_request",
        "title": "New friend request",
        "message": "Erik van Dijk sent you a friend request",
        "data": {
          "user_id": 2,
          "request_id": 888
        },
        "is_read": 0,
        "created_at": "2025-10-17T16:30:00Z"
      }
    ],
    "unread_count": 5,
    "pagination": {...}
  }
}
```

#### PUT `/notifications/{notification_id}/read`
**Description**: Mark notification as read

#### PUT `/notifications/read-all`
**Description**: Mark all notifications as read

---

### 10. Weather

#### GET `/weather`
**Description**: Get fishing weather forecast

**Query Parameters**:
- `latitude` (float, required)
- `longitude` (float, required)

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "current": {
      "temperature": 18,
      "weather": "Partly cloudy",
      "wind_speed": 12,
      "wind_direction": "NW",
      "pressure": 1015,
      "humidity": 65
    },
    "fishing_conditions": {
      "rating": "Good",
      "best_time": "Early morning (06:00-09:00)",
      "tips": ["Barometer is stable", "Wind is favorable"]
    },
    "forecast": [...]
  }
}
```

---

### 11. Dashboard

#### GET `/dashboard`
**Description**: Get dashboard data (recent posts, stats, etc.)

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "user_stats": {
      "catches": 42,
      "posts": 15,
      "friends": 28
    },
    "recent_posts": [...],
    "recent_catches": [...],
    "friend_activity": [...],
    "notifications_count": 5
  }
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Invalid request parameters",
    "details": {
      "email": ["Email is required"],
      "password": ["Password must be at least 8 characters"]
    }
  }
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication required"
  }
}
```

### 403 Forbidden
```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "You don't have permission to access this resource"
  }
}
```

### 404 Not Found
```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Resource not found"
  }
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An unexpected error occurred"
  }
}
```

---

## Rate Limiting

- **Rate Limit**: 100 requests per minute per user
- **Header**: `X-RateLimit-Remaining: 95`
- **Reset**: 60 seconds

## Versioning

API version is specified in the URL: `/api/v1/`

Current version: **v1**
