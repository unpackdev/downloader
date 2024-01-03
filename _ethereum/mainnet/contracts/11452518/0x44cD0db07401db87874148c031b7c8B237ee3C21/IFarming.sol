pragma solidity ^0.6.6;

import "./IERC20.sol";

interface IFarming {
    // Events
    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount,
        uint256 rewards
    );

    function createPool(IERC20, uint256) external;

    function deposit(uint256, uint256) external;

    function withdraw(uint256, uint256) external;

    function bulkUpgradePools() external;

    function upgradePool(uint256) external;

    function waitingRewards(uint256, address) external view returns (uint256);

    function updateRewardsPerPool() external;

    function countPools() external view returns (uint256);
}
