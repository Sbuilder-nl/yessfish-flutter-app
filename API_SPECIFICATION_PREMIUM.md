# YessFish Premium & Viskaart System - API Specification

## Premium Tiers

### 1. Free Tier
- Basic posts & catches
- 3 albums maximum
- Basic fishing spots
- Basic weather
- Ads supported

### 2. Premium Maandelijks (€4.99/maand)
- Premium Viskaart (detailed fishing map)
- Premium Weather data (hourly, 14-day forecast)
- Unlimited albums
- No ads
- Priority support

### 3. Premium Jaarlijks (€49.99/jaar) - **17% korting**
- All Premium Monthly features
- Yearly badge
- Special yearly-only features
- Priority in tournaments

---

## Premium Viskaart API Endpoints

### GET `/premium/viskaart`
**Description**: Get premium fishing card with detailed spots, regulations, and fish population data

**Authentication**: Required (Premium users only)

**Query Parameters**:
- `latitude` (float, optional)
- `longitude` (float, optional)
- `radius` (int, default: 100km, max: 500km)
- `water_type` (string, optional) - Options: lake, river, canal, sea
- `fish_species` (array, optional) - Filter by fish species
- `facilities` (array, optional) - Filter by facilities

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "premium_spots": [
      {
        "id": 789,
        "name": "Zuidlaardermeer",
        "type": "lake",
        "water_type": "Freshwater",
        "size_hectares": 720,
        "max_depth_meters": 4.5,
        "location": {
          "latitude": 53.1336,
          "longitude": 6.6992,
          "province": "Groningen",
          "municipality": "Tynaarlo"
        },
        "premium_data": {
          "fish_population": {
            "carp": {
              "abundance": "High",
              "avg_weight_kg": 5.2,
              "record_weight_kg": 18.5,
              "best_season": ["April-October"],
              "best_baits": ["Boilies", "Corn", "Pellets"]
            },
            "pike": {
              "abundance": "Medium",
              "avg_weight_kg": 3.5,
              "record_weight_kg": 12.8,
              "best_season": ["October-March"],
              "best_baits": ["Live bait", "Spinners"]
            },
            "perch": {
              "abundance": "High",
              "avg_weight_kg": 0.4,
              "record_weight_kg": 1.2,
              "best_season": ["Year-round"],
              "best_baits": ["Worms", "Small spinners"]
            }
          },
          "regulations": {
            "license_required": true,
            "vispas_accepted": true,
            "daily_limit": {
              "carp": 2,
              "pike": 3,
              "perch": 10
            },
            "size_limits": {
              "pike_min_cm": 45,
              "carp_min_cm": null
            },
            "catch_and_release": ["carp_over_5kg"],
            "closed_seasons": [
              {
                "species": "pike",
                "period": "March 1 - May 31"
              }
            ],
            "night_fishing_allowed": true,
            "boat_fishing_allowed": true
          },
          "facilities": {
            "parking": {
              "available": true,
              "spaces": 50,
              "cost": "Free"
            },
            "toilets": true,
            "fishing_platforms": {
              "count": 12,
              "accessible": true
            },
            "boat_launch": true,
            "camping": {
              "available": false
            },
            "tackle_shop": {
              "available": true,
              "distance_km": 2.5,
              "name": "Hengelsport Groningen"
            }
          },
          "access": {
            "open_24_7": true,
            "fee": "Vispas required",
            "wheelchair_accessible": true
          },
          "water_quality": {
            "visibility_m": 2.5,
            "temperature_c": 16,
            "ph": 7.8,
            "oxygen_mg_l": 8.5,
            "last_updated": "2025-10-15T10:00:00Z"
          },
          "weather_impact": {
            "wind_protection": "Good on south shore",
            "best_wind": "Southwest 5-15 km/h",
            "danger_zones": ["North shore in storm"]
          },
          "hot_spots": [
            {
              "name": "De Punt",
              "latitude": 53.1350,
              "longitude": 6.6980,
              "species": ["carp", "pike"],
              "description": "Deep water near bridge, excellent for large carp",
              "best_time": "Dawn and dusk",
              "difficulty": "Intermediate"
            },
            {
              "name": "Rietoevers Oost",
              "latitude": 53.1320,
              "longitude": 6.7050,
              "species": ["perch", "roach"],
              "description": "Shallow reedy area, perfect for beginners",
              "best_time": "Midday",
              "difficulty": "Beginner"
            }
          ],
          "recent_catches": [
            {
              "species": "carp",
              "weight_kg": 12.3,
              "caught_at": "2025-10-15T06:30:00Z",
              "bait_used": "Strawberry boilies",
              "user_name": "Anonymous"
            }
          ],
          "tide_info": null,
          "current_info": null
        },
        "user_stats": {
          "visits": 24,
          "catches": 18,
          "last_visit": "2025-10-10T08:00:00Z",
          "favorite": true
        },
        "community_rating": {
          "overall": 4.7,
          "accessibility": 4.9,
          "fish_stock": 4.5,
          "facilities": 4.6,
          "scenery": 4.8,
          "total_reviews": 186
        },
        "images": [
          {
            "url": "https://yessfish.com/uploads/spots/zuidlaardermeer1.jpg",
            "caption": "Main fishing platform",
            "uploaded_by": "Richard Sip",
            "uploaded_at": "2024-08-15T12:00:00Z"
          }
        ],
        "created_at": "2024-06-01T10:00:00Z",
        "updated_at": "2025-10-15T10:00:00Z"
      }
    ],
    "user_location": {
      "latitude": 53.2194,
      "longitude": 6.5665
    },
    "premium_active": true,
    "premium_expires": "2026-10-17T00:00:00Z"
  }
}
```

---

### GET `/premium/viskaart/regulations/{province}`
**Description**: Get detailed fishing regulations for a province

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "province": "Groningen",
    "regulations": {
      "license_types": [
        {
          "name": "VISpas Groot",
          "price": 52.50,
          "validity": "Full year",
          "waters": "All VISpas waters in NL"
        },
        {
          "name": "VISpas Klein",
          "price": 40.00,
          "validity": "Full year",
          "waters": "Limited to specific clubs"
        }
      ],
      "general_rules": [
        "Maximum 2 rods per person",
        "Barbless hooks recommended for carp",
        "Live bait regulations apply"
      ],
      "protected_species": ["sturgeon", "salmon"],
      "size_limits": {...},
      "bag_limits": {...}
    }
  }
}
```

---

### GET `/premium/weather/detailed`
**Description**: Get detailed premium weather data for fishing

**Authentication**: Required (Premium users only)

**Query Parameters**:
- `latitude` (float, required)
- `longitude` (float, required)
- `hours` (int, default: 48, max: 336 for premium users)

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "current": {
      "time": "2025-10-17T16:00:00Z",
      "temperature_c": 18,
      "feels_like_c": 16,
      "weather": "Partly cloudy",
      "weather_code": 2,
      "wind_speed_kmh": 12,
      "wind_direction": "NW",
      "wind_gusts_kmh": 18,
      "pressure_mb": 1015,
      "pressure_trend": "rising",
      "humidity_percent": 65,
      "visibility_km": 10,
      "uv_index": 4,
      "cloud_cover_percent": 40,
      "precipitation_mm": 0,
      "precipitation_probability": 10
    },
    "fishing_conditions": {
      "rating": "Excellent",
      "rating_score": 9.2,
      "best_times_today": [
        {
          "start": "06:00",
          "end": "09:00",
          "reason": "Dawn feeding time, optimal barometer"
        },
        {
          "start": "18:00",
          "end": "21:00",
          "reason": "Dusk feeding time, stable conditions"
        }
      ],
      "factors": {
        "barometer": {
          "value": 1015,
          "status": "Ideal",
          "impact": "Positive",
          "description": "Stable pressure, active fish"
        },
        "wind": {
          "speed": 12,
          "direction": "NW",
          "status": "Good",
          "impact": "Positive",
          "description": "Light breeze, good for shore fishing"
        },
        "temperature": {
          "value": 18,
          "status": "Ideal",
          "impact": "Positive",
          "description": "Perfect temperature for active fish"
        },
        "moon_phase": {
          "phase": "Waxing Gibbous",
          "illumination": 76,
          "status": "Good",
          "impact": "Neutral",
          "description": "Active fish during bright moon"
        },
        "tide": null,
        "water_temperature": {
          "estimated_c": 16,
          "status": "Good",
          "impact": "Positive"
        }
      },
      "tips": [
        "Use topwater lures in early morning",
        "Fish windward shores for active predators",
        "Barometer is stable - expect consistent bites"
      ]
    },
    "hourly_forecast": [
      {
        "time": "2025-10-17T17:00:00Z",
        "temperature_c": 17,
        "weather": "Partly cloudy",
        "wind_speed_kmh": 10,
        "precipitation_mm": 0,
        "precipitation_probability": 5,
        "fishing_score": 8.5
      }
    ],
    "daily_forecast": [
      {
        "date": "2025-10-18",
        "temperature_min_c": 12,
        "temperature_max_c": 19,
        "weather": "Sunny",
        "sunrise": "07:45",
        "sunset": "18:30",
        "moonrise": "14:20",
        "moonset": "02:15",
        "moon_phase": "Waxing Gibbous",
        "best_fishing_times": ["06:30-09:00", "18:00-20:30"],
        "fishing_rating": "Excellent",
        "fishing_score": 9.5
      }
    ],
    "solunar_forecast": {
      "major_periods": [
        {
          "start": "06:15",
          "end": "08:15",
          "type": "Major",
          "activity_level": "High"
        },
        {
          "start": "18:30",
          "end": "20:30",
          "type": "Major",
          "activity_level": "High"
        }
      ],
      "minor_periods": [
        {
          "start": "12:00",
          "end": "13:00",
          "type": "Minor",
          "activity_level": "Medium"
        }
      ]
    },
    "alerts": []
  }
}
```

---

## Premium Subscription Endpoints

### GET `/premium/plans`
**Description**: Get available premium plans

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "plans": [
      {
        "id": "premium_monthly",
        "name": "Premium Maandelijks",
        "price": 4.99,
        "currency": "EUR",
        "interval": "month",
        "features": [
          "Premium Viskaart",
          "Detailed weather (14 dagen)",
          "Unlimited albums",
          "No ads",
          "Priority support"
        ],
        "badge": "⭐ Premium"
      },
      {
        "id": "premium_yearly",
        "name": "Premium Jaarlijks",
        "price": 49.99,
        "currency": "EUR",
        "interval": "year",
        "discount_percentage": 17,
        "features": [
          "All Premium Monthly features",
          "17% discount",
          "Yearly exclusive badge",
          "Tournament priority",
          "Beta features access"
        ],
        "badge": "🏆 Premium Pro",
        "popular": true
      }
    ]
  }
}
```

### POST `/premium/subscribe`
**Description**: Subscribe to premium plan

**Request Body**:
```json
{
  "plan_id": "premium_yearly",
  "payment_method": "ideal",
  "return_url": "yessfish://premium/success"
}
```

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "subscription_id": "sub_abc123",
    "status": "pending",
    "payment_url": "https://payments.mollie.com/...",
    "expires_at": null
  }
}
```

### GET `/premium/status`
**Description**: Get current premium status

**Response Success (200)**:
```json
{
  "success": true,
  "data": {
    "is_premium": true,
    "plan_id": "premium_yearly",
    "plan_name": "Premium Jaarlijks",
    "started_at": "2024-10-17T00:00:00Z",
    "expires_at": "2025-10-17T00:00:00Z",
    "auto_renew": true,
    "features": [
      "premium_viskaart",
      "premium_weather",
      "unlimited_albums",
      "no_ads"
    ]
  }
}
```

### POST `/premium/cancel`
**Description**: Cancel premium subscription

**Response Success (200)**:
```json
{
  "success": true,
  "message": "Subscription cancelled. Premium features will remain active until 2025-10-17"
}
```

---

## Premium Features Implementation

### Viskaart Features
1. **Detailed Spot Information**
   - Fish population data
   - Size and bag limits
   - Best baits & techniques
   - Hot spots coordinates
   - Recent catches

2. **Regulations Database**
   - Province-specific rules
   - License requirements
   - Protected species
   - Seasonal closures

3. **Water Quality Data**
   - Real-time water temperature
   - pH levels
   - Oxygen content
   - Visibility conditions

4. **Community Intelligence**
   - Recent catch reports
   - User ratings
   - Photo galleries
   - Tips from local anglers

### Premium Weather Features
1. **Extended Forecasts**
   - 14-day forecast (vs 7-day free)
   - Hourly data (vs daily free)
   - Minute-by-minute precipitation

2. **Fishing-Specific Data**
   - Solunar charts
   - Barometric pressure trends
   - Fish activity predictions
   - Best fishing times

3. **Advanced Alerts**
   - Optimal fishing condition notifications
   - Weather warnings
   - Moon phase alerts

### Other Premium Features
- Unlimited photo albums
- No advertisements
- Priority customer support
- Early access to new features
- Tournament priority registration
- Custom catch statistics
- Export fishing journal to PDF
