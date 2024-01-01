// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice VSP interface
 */
interface IVsp {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
}
