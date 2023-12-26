// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @notice IRageQuit interface
 * @dev Source: https://github.com/ampleforth/token-geyser-v2/blob/c878fd6ba5856d818ff41c54bce59c9413bc93c9/contracts/Geyser.sol#L17-L19
 */
interface IRageQuit {
    /**
     * @notice Exit without claiming reward
     * @dev Should only be callable by the vault directly
     */
    function rageQuit() external;
}
