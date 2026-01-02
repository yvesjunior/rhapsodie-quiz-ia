# Rhapsody Quiz - Architecture Documentation

## Current Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
├─────────────────────────────────────────────────────────────────┤
│  UI Layer (Screens/Widgets)                                      │
│     ↓                                                            │
│  State Management (Cubits/BLoC)                                  │
│     ↓                                                            │
│  Repositories (Business Logic)                                   │
│     ↓                                                            │
│  Data Sources (Remote/Local)                                     │
└─────────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────┐    ┌─────────────────┐    ┌─────────────┐
│   Backend   │    │    Firebase     │    │    Hive     │
│  (PHP/MySQL)│    │  (Firestore)    │    │  (Local DB) │
│             │    │  (FCM)          │    │             │
│  - Users    │    │  - Battle Rooms │    │  - Cache    │
│  - Questions│    │  - Messages     │    │  - Offline  │
│  - Contests │    │  - Auth         │    │             │
│  - Scores   │    │                 │    │             │
└─────────────┘    └─────────────────┘    └─────────────┘
```

---

## Future Architecture: Battle Room Provider Abstraction

### Goal
Add a feature flag to switch between **Firestore** (current) and **WebSocket** (self-hosted) for battle rooms, enabling cost optimization and full infrastructure control.

### Motivation
- **Cost**: Firestore charges per read/write; WebSocket is flat server cost
- **Control**: Self-hosted solution removes vendor lock-in
- **Latency**: Direct WebSocket can be faster for real-time battles

### Proposed Config

```dart
// lib/core/config/config.dart

/// Battle room realtime provider
/// - firestore: Uses Firebase Firestore (default, managed)
/// - websocket: Uses self-hosted WebSocket server
enum BattleRoomProvider { firestore, websocket }

const battleRoomProvider = BattleRoomProvider.firestore;

// WebSocket server URL (only used when provider = websocket)
const websocketServerUrl = 'wss://battles.rhapsody-quiz.com';
```

### Implementation Plan

| Phase | Task | Effort | Priority |
|-------|------|--------|----------|
| 1 | Create `BattleRoomProviderInterface` abstract class | 2h | High |
| 2 | Rename `BattleRoomRemoteDataSource` → `FirestoreBattleRoomProvider` | 1h | High |
| 3 | Implement interface in Firestore provider | 2h | High |
| 4 | Create `WebSocketBattleRoomProvider` (stub) | 4h | Medium |
| 5 | Add `BattleRoomProviderFactory` with config switch | 1h | High |
| 6 | Build WebSocket server (Node.js + Socket.io) | 2-3 days | Medium |
| 7 | Test both providers with feature flag | 1 day | High |
| 8 | Deploy WebSocket server infrastructure | 1 day | Low |

### Proposed File Structure

```
lib/features/battle_room/
├── providers/
│   ├── battle_room_provider.dart           # Abstract interface
│   ├── firestore_battle_room_provider.dart # Current Firestore implementation
│   └── websocket_battle_room_provider.dart # Future WebSocket implementation
├── battle_room_provider_factory.dart       # Factory with env-based selection
├── battle_room_repository.dart             # Uses provider via factory
└── cubits/
    ├── battle_room_cubit.dart
    └── multi_user_battle_room_cubit.dart
```

### Abstract Interface (Proposed)

```dart
abstract class BattleRoomProvider {
  // Room lifecycle
  Future<String> createRoom(BattleRoomConfig config);
  Future<void> joinRoom(String roomId, UserDetails user);
  Future<void> deleteRoom(String roomId);
  
  // Realtime subscription
  Stream<BattleRoom> subscribeToRoom(String roomId);
  
  // Answer submission
  Future<void> submitAnswer({
    required String roomId,
    required String odId,
    required String odId,
    required Map<String, String> answer,
    required int correctAnswers,
  });
  
  // Messages
  Future<void> sendMessage(String roomId, Message message);
  Stream<List<Message>> subscribeToMessages(String roomId);
  
  // Cleanup
  void dispose();
}
```

### WebSocket Server (Proposed - Node.js)

```javascript
// server/battle-room-server.js
const io = require('socket.io')(server);

io.on('connection', (socket) => {
  socket.on('create_room', (data) => { /* ... */ });
  socket.on('join_room', (roomId, user) => { /* ... */ });
  socket.on('submit_answer', (roomId, answer) => { /* ... */ });
  socket.on('leave_room', (roomId) => { /* ... */ });
});
```

### When to Implement

| Trigger | Action |
|---------|--------|
| Firebase costs > $100/month | Begin Phase 1-5 |
| Firebase costs > $200/month | Complete all phases |
| Need self-hosted infrastructure | Complete all phases |
| Performance issues with Firestore | Evaluate and implement |

### Cost Comparison

| Solution | 1K DAU | 10K DAU | 100K DAU |
|----------|--------|---------|----------|
| Firebase Firestore | ~$20/mo | ~$150/mo | ~$1,500/mo |
| Self-hosted WebSocket | $10/mo | $25/mo | $100/mo |

---

## Other Future Considerations

### 1. Push Notification Alternatives
Currently using FCM (free). If needed, alternatives:
- OneSignal (free tier available)
- Self-hosted with ntfy.sh

### 2. Offline-First Enhancements
Current: Hive caching with network-first strategy
Future: Consider full offline sync with conflict resolution

### 3. Backend Migration
Current: PHP/CodeIgniter + MySQL
Future consideration: Node.js/Go for better WebSocket integration

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-02 | Keep Firestore for v1.0 launch | Faster time to market, proven reliability |
| 2026-01-02 | Plan WebSocket abstraction | Future cost optimization, documented for v2.0 |

---

*Last updated: 2026-01-02*
