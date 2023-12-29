// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/**
 * @notice ICurvePool interface
 */
interface ICurvePool {
    /**
     * @notice Perform an exchange between two coins
     * @dev Index values can be found via the `coins` public getter method
     * @param sourceTokenIndex Index value for the coin to send
     * @param targetTokenIndex Index valie of the coin to recieve
     * @param dx Amount of `sourceToken` being exchanged
     * @param min_dy Minimum amount of `targetToken` to receive
     * @return Actual amount of `targetToken` received
     */
    function exchange(int128 sourceTokenIndex, int128 targetTokenIndex, uint256 dx, uint256 min_dy) external payable returns (uint256);
}
