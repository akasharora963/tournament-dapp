// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library Sort {
    /**
     * @dev Sorts scores and associated player addresses in descending order using Quick Sort.
     * @param players Array of player addresses.
     * @param scores Array of scores corresponding to the players.
     * @param left The starting index for sorting.
     * @param right The ending index for sorting.
     */
    function sort(
        address[] memory players,
        uint256[] memory scores,
        int256 left,
        int256 right
    ) internal pure {
        if (left >= right) return;

        uint256 pivot = scores[uint256(left + (right - left) / 2)];
        int256 i = left;
        int256 j = right;

        while (i <= j) {
            while (scores[uint256(i)] > pivot) i++;
            while (scores[uint256(j)] < pivot) j--;

            if (i <= j) {
                // Swap scores
                (scores[uint256(i)], scores[uint256(j)]) = (scores[uint256(j)], scores[uint256(i)]);
                // Swap players
                (players[uint256(i)], players[uint256(j)]) = (players[uint256(j)], players[uint256(i)]);
                i++;
                j--;
            }
        }

        if (left < j) sort(players, scores, left, j);
        if (i < right) sort(players, scores, i, right);
    }
}
