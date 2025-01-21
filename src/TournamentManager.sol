// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./PlayerRegistery.sol";
import "./TimeLock.sol";
import "./Sort.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TournamentManager is ReentrancyGuard, Ownable {
    using Sort for address[];

    enum GAME_TYPE {
        ARCADE,
        MOBA,
        STARATAGIC
    }

    enum TOURNAMENT_STATUS {
        CREATED,
        ACTIVE,
        ENDED,
        CANCELLED
    }

    struct PLAYER {
        uint256 _contribution;
        uint256 _score;
    }

    struct Tournament {
        uint256 id;
        uint256 entryFee;
        uint256 maxPlayers; // max
        uint256 startTime;
        uint256 endTime;
        GAME_TYPE gameType;
        uint256 totalPlayers;
        uint256 prizePool; // Tournament-specific balance
        TOURNAMENT_STATUS status;
    }

    PlayerRegistry public playerRegistry;
    TimeLock public timeLock;

    uint256 public constant MAX_ALLOWED_PLAYERS = 10;

    uint256 public tournamentId;
    mapping(uint256 => Tournament) public tournaments;
    mapping(uint256 => mapping(address => bool)) public hasJoined;
    mapping(uint256 => address[]) public tournamentPlayers;
    mapping(uint256 => mapping(address => PLAYER)) public playerData;

    event TournamentCreated(
        uint256 id,
        uint256 entryFee,
        uint256 maxPlayers,
        uint256 startTime,
        uint256 endTime
    );
    event PlayerJoined(uint256 tournamentId, address player);
    event RewardsDistributed(
        uint256 tournamentId,
        uint256 totalPrize,
        address[] winners
    );

    constructor(
        address _admin,
        address _playerRegistry,
        address _timeLock
    ) Ownable(_admin) {
        playerRegistry = PlayerRegistry(_playerRegistry);
        timeLock = TimeLock(_timeLock);
    }

    receive() external payable{}

    function createTournament(
        uint256 _entryFee,
        uint256 _maxPlayers,
        uint256 _startTime,
        uint256 _duration,
        GAME_TYPE _gameType
    ) external onlyOwner {
        require(_startTime > block.timestamp, "Invalid start time");
        require(_entryFee > 0, "Entry fee must be greater than zero");
        require(
            _maxPlayers > 0 && _maxPlayers <= MAX_ALLOWED_PLAYERS,
            "Invalid max players"
        );

        uint256 _endTime = _startTime + _duration;

        Tournament storage tournament = tournaments[tournamentId];
        tournament.id = tournamentId;
        tournament.entryFee = _entryFee;
        tournament.maxPlayers = _maxPlayers;
        tournament.startTime = _startTime;
        tournament.endTime = _endTime;
        tournament.gameType = _gameType;
        tournament.status = TOURNAMENT_STATUS.CREATED;

        // Set time lock for score submissions
        timeLock.setLock(tournamentId, _endTime);

        emit TournamentCreated(
            tournamentId,
            _entryFee,
            _maxPlayers,
            _startTime,
            _endTime
        );
        tournamentId++;
    }

    function startGame(uint256 _id) external onlyOwner {
        Tournament storage tournament = tournaments[_id];
        require(
            tournament.totalPlayers == tournament.maxPlayers,
            "Lobby not full"
        );

        tournament.status = TOURNAMENT_STATUS.ACTIVE;
    }

    function joinTournament(uint256 _id) external payable {
        Tournament storage tournament = tournaments[_id];
        require(
            block.timestamp < tournament.startTime,
            "Tournament already started"
        );
        require(
            tournament.totalPlayers < tournament.maxPlayers,
            "Tournament full"
        );
        require(!hasJoined[_id][msg.sender], "Already joined");

        uint256 fee = tournament.entryFee;
        if (playerRegistry.hasBadge(msg.sender)) {
            fee = (fee * 90) / 100; // 10% discount for badge holders
        }
        require(msg.value == fee, "Incorrect entry fee");

        // Add to the tournament's prize pool
        tournament.prizePool += fee;

        playerData[_id][msg.sender] = PLAYER(msg.value, 0);
        tournamentPlayers[_id].push(msg.sender);

        tournament.totalPlayers++;
        hasJoined[_id][msg.sender] = true;

        emit PlayerJoined(_id, msg.sender);
    }

    function submitScores(
        uint256 _id,
        uint256[] calldata _scores
    ) external onlyOwner {
        require(
            block.timestamp <= timeLock.lockEndTimes(_id),
            "Submission window closed"
        );
        require(
            _scores.length == tournamentPlayers[_id].length,
            "Scores array length mismatch"
        );

        uint256 _players = tournamentPlayers[_id].length;

        for (uint256 i = 0; i < _players; i++) {
            address _player = tournamentPlayers[_id][i];

            playerData[_id][_player]._score = _scores[i];
        }
    }

    function finalizeTournament(
        uint256 _id
    ) external onlyOwner returns (TOURNAMENT_STATUS _status) {
        Tournament storage tournament = tournaments[_id];
        require(block.timestamp > tournament.endTime, "Tournament not ended");
        require(
            tournament.status == TOURNAMENT_STATUS.CREATED ||
                tournament.status == TOURNAMENT_STATUS.ACTIVE,
            "Tournament already finalized"
        );

        if (tournament.totalPlayers < tournament.maxPlayers) {
            tournament.status = TOURNAMENT_STATUS.CANCELLED;

            uint256 _players = tournamentPlayers[_id].length;

            tournament.prizePool = 0;

            for (uint256 i = 0; i < _players; i++) {
                address _player = tournamentPlayers[_id][i];
                uint256 _contribution = playerData[_id][_player]._contribution;
                (bool sent, ) = _player.call{value: _contribution}("");
                require(sent, "Failed to refund");
            }

            return TOURNAMENT_STATUS.CANCELLED;
        }

        tournament.status = TOURNAMENT_STATUS.ENDED;

        // Distribute rewards
        distributeRewards(_id);

        return TOURNAMENT_STATUS.ENDED;
    }

    function distributeRewards(uint256 _id) internal {
        Tournament storage tournament = tournaments[_id];
        uint256 totalPrize = tournament.prizePool;
        require(
            address(this).balance >= totalPrize,
            "Insufficient contract balance for rewards"
        );

        address[] memory winners = getTopPlayers(_id);

        // Reward distribution logic using call (50% - 1st, 30% - 2nd, 20% - 3rd)
        if (winners.length >= 1) {
            (bool success, ) = winners[0].call{value: (totalPrize * 50) / 100}(
                ""
            );
            require(success, "Transfer to 1st winner failed");
        }
        if (winners.length >= 2) {
            (bool success, ) = winners[1].call{value: (totalPrize * 30) / 100}(
                ""
            );
            require(success, "Transfer to 2nd winner failed");
        }
        if (winners.length >= 3) {
            (bool success, ) = winners[2].call{value: (totalPrize * 20) / 100}(
                ""
            );
            require(success, "Transfer to 3rd winner failed");
        }

        tournament.prizePool = 0;

        emit RewardsDistributed(_id, totalPrize, winners);
    }

    // Function to fetch top players using Quick Sort
    function getTopPlayers(uint256 _id) public view returns (address[] memory) {
        uint256 players = tournamentPlayers[_id].length;
        address[] memory sortedPlayers = new address[](players);
        uint256[] memory scores = new uint256[](players);

        for (uint256 i = 0; i < players; i++) {
            address player = tournamentPlayers[_id][i];
            scores[i] = playerData[_id][player]._score;
            sortedPlayers[i] = player;
        }

        // Sort players using the QuickSort library
        sortedPlayers.sort(scores, 0, int256(players - 1));
        return sortedPlayers;
    }
}
