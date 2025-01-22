// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PlayerRegistry is ERC721, Ownable {
    uint256 public playerCount;
    uint256 public badgeCount; // Track the number of badges issued
    mapping(address => bool) public isRegistered;
    mapping(address => bool) public hasBadge;

    event PlayerRegistered(address indexed player, uint256 playerId);
    event BadgeIssued(address indexed player, uint256 tokenId);

    constructor(address _admin) ERC721("TournamentBadge", "TB") Ownable(_admin) {}

    /// @dev Players can register themselves
    function registerPlayer() external {
        require(!isRegistered[msg.sender], "Already registered");

        playerCount++;
        isRegistered[msg.sender] = true;

        emit PlayerRegistered(msg.sender, playerCount);
    }

    /// @dev Admin (owner) can issue badges to selected players
    /// @param player Address of the player to issue the badge
    function issueBadge(address player) external onlyOwner {
        require(isRegistered[player], "Player not registered");
        require(!hasBadge[player], "Badge already issued");

        badgeCount++;
        hasBadge[player] = true;

        uint256 tokenId = badgeCount; // Unique tokenId based on badge count
        _mint(player, tokenId);

        emit BadgeIssued(player, tokenId);
    }
}
