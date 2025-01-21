// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract TimeLock {
    mapping(uint256 => uint256) public lockEndTimes;

    event LockSet(uint256 indexed tournamentId, uint256 endTime);

    /// @notice Sets a lock for a specific tournament until a specified end time
    function setLock(uint256 tournamentId, uint256 endTime) external {
        require(endTime > block.timestamp, "End time must be in the future");
        lockEndTimes[tournamentId] = endTime;
        emit LockSet(tournamentId, endTime);
    }

    /// @notice Checks if the lock for a tournament has expired
    function isUnlocked(uint256 tournamentId) external view returns (bool) {
        return block.timestamp > lockEndTimes[tournamentId];
    }
}
