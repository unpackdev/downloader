pragma solidity ^0.6.0;

/**
 * @title IStakingManager
 * @dev Staking manager interface
 */
interface IStakingManager {
    function addStake(
        address user,
        address pool,
        uint256 amount
    ) external;

    function startTime() external view returns (uint256);

    function endTime() external view returns (uint256);

    function getPools() external view returns (address[4] memory);
}
