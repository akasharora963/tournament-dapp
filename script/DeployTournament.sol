// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/PlayerRegistery.sol";
import "../src/TimeLock.sol";
import "../src/TournamentManager.sol";

contract DeployTournament is Script {
    uint256 public deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");

    address public _admin = vm.envAddress("ADMIN");

    function run() external {
        vm.startBroadcast(deployPrivateKey);

        // Deploy Player Registry
        PlayerRegistry _pr = new PlayerRegistry(_admin);
        console.log("Player Registery deployed at:", address(_pr));

        // Deploy TimeLock
        TimeLock _tl = new TimeLock();
        console.log("TimeLock deployed at:", address(_tl));

        // Deploy tournament
        TournamentManager _tm = new TournamentManager(_admin, address(_pr), address(_tl));

        console.log("Tournamaent Manager deployed at:", address(_tm));

        vm.stopBroadcast();
    }
}
