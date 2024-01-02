// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title IDeltaPoolController
 * @dev IDeltaPoolController interface
 * create stakePool
 */
interface IDeltaPoolController {
    /**
     * @dev developer wallet address
     */
    function getDevAddress() external view returns (address);

    /*
     * @dev get level by stake amount
     * @param stakeAmount stake amount
     * @return  level
     */
    function getLevelByAmount(
        uint256 stakeAmount
    ) external view returns (uint256);

    /*
     * @dev get max vip level
     * @return max vip level
     */
    function getMaxLevel() external view returns (uint256);

    /*
     * @dev get share alloc
     * @param level user level
     * @return share alloc
     */
    function getShareAlloc(uint256 level) external view returns (uint256);
}
