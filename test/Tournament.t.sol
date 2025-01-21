// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/TournamentManager.sol";
import "../src/PlayerRegistery.sol";
import "../src/TimeLock.sol";

contract TournamentManagerTest is Test {
    TournamentManager tournamentManager;
    PlayerRegistry playerRegistry;
    TimeLock timeLock;
    address admin;
    address player1;
    address player2;
    address player3;

    function setUp() public {
        admin = address(0x1);
        player1 = address(0x2);
        player2 = address(0x3);
        player3 = address(0x4);

        vm.startPrank(admin);

        playerRegistry = new PlayerRegistry(admin);
        timeLock = new TimeLock();
        tournamentManager = new TournamentManager(admin, address(playerRegistry), address(timeLock));

        vm.stopPrank();
    }

    function testCreateTournament() public {
        vm.startPrank(admin);

        uint256 entryFee = 1 ether;
        uint256 maxPlayers = 3;
        uint256 startTime = block.timestamp + 1 hours;
        uint256 duration = 2 hours;

        tournamentManager.createTournament(
            entryFee,
            maxPlayers,
            startTime,
            duration,
            TournamentManager.GAME_TYPE.ARCADE
        );

        (uint256 id, uint256 fee, uint256 max, , , , , uint256 prizePool, TournamentManager.TOURNAMENT_STATUS status) = tournamentManager.tournaments(0);
        assertEq(id, 0);
        assertEq(fee, entryFee);
        assertEq(max, maxPlayers);
        assertEq(prizePool, 0);
        assertEq(uint256(status), uint256(TournamentManager.TOURNAMENT_STATUS.CREATED));

        vm.stopPrank();
    }

    function testJoinTournament() public {
        vm.startPrank(admin);

        uint256 entryFee = 1 ether;
        uint256 maxPlayers = 3;
        uint256 startTime = block.timestamp + 1 hours;
        uint256 duration = 2 hours;

        tournamentManager.createTournament(
            entryFee,
            maxPlayers,
            startTime,
            duration,
            TournamentManager.GAME_TYPE.ARCADE
        );

        vm.stopPrank();

        vm.startPrank(player1);
        vm.deal(player1, 2 ether);

        tournamentManager.joinTournament{value: entryFee}(0);

        (, , , , , , uint256 totalPlayers, uint256 prizePool, ) = tournamentManager.tournaments(0);
        assertEq(totalPlayers, 1);
        assertEq(prizePool, entryFee);

        vm.stopPrank();
    }

}
