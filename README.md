# TournamentManager Project

## Overview
The **TournamentManager** contract enables the creation, management, and execution of decentralized tournaments. It allows players to join tournaments by paying an entry fee, records scores, and distributes rewards among winners. The project uses Foundry for contract development and deployment.

---

## Features
- **Tournament Management**: Admins can create tournaments with specific parameters.
- **Player Registration**: Integration with the `PlayerRegistry` contract for player management.
- **Time Lock**: Prevent late score submissions using the `TimeLock` contract.
- **Prize Distribution**: Distributes rewards among top players based on scores.
- **Custom Sorting**: Utilizes a custom sorting library (`Sort.sol`) for leaderboard ranking.
- **Discounts for Badge Holders**: Badge holders receive a discounted entry fee.

---

## Smart Contracts
### 1. **TournamentManager.sol**
- **Admin Functions**:
  - `createTournament`: Create a new tournament.
  - `startGame`: Start a tournament when the lobby is full.
  - `submitScores`: Submit scores for players.
  - `finalizeTournament`: Finalize the tournament, distribute rewards, or refund players if canceled.

- **Player Functions**:
  - `joinTournament`: Join a tournament by paying the entry fee.

- **Utility Functions**:
  - `getTopPlayers`: Fetch top players for a tournament using QuickSort.

### 2. **PlayerRegistry.sol**
Manages player registration and badge verification.

### 3. **TimeLock.sol**
Handles score submission time locking for tournaments.

### 4. **Sort.sol**
Utility library for sorting players based on scores.

---

## Setup Instructions

### Prerequisites
- Install Foundry:
  ```bash
  curl -L https://foundry.paradigm.xyz | bash
  foundryup
  ```
- Install dependencies:
  ```bash
  forge install OpenZeppelin/openzeppelin-contracts
  ```

---

### Project Structure
```
TournamentManagerProject
├── src
│   ├── TournamentManager.sol
│   ├── PlayerRegistry.sol
│   ├── TimeLock.sol
│   └── Sort.sol
├── test
│   └── TournamentManager.t.sol
├── foundry.toml
└── README.md
```

---

### Steps to Deploy Contracts

1. **Compile Contracts**:
   ```bash
   forge build
   ```

2. **Deploy Tournament**:
   ```bash
   forge script script/DeployTournament.sol:DeployTournament --broadcast --slow --rpc-url blastSepolia -vvv 
   ```

3. **Verify Deployment**:
   Use Foundry scripts or interact with contracts on a test network to verify functionality.

---

## Testing

1. **Run Local Network**:
   ```bash
   anvil
   ```

2. **Write Tests**:
   Add test cases in `test/TournamentManager.t.sol` to verify:
   - Tournament creation and joining.
   - Score submission and rewards distribution.
   - Time lock functionality.

3. **Run Tests**:
   ```bash
   forge test
   ```







