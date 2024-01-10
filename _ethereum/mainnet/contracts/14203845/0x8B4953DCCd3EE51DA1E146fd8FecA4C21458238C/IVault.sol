// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "IStrategy.sol";
import "IPreparable.sol";

/**
 * @title Interface for a Vault
 */

interface IVault is IPreparable {
    function initialize(
        address _pool,
        uint256 _debtLimit,
        uint256 _targetAllocation,
        uint256 _bound
    ) external;

    function getStrategy() external view returns (IStrategy);

    function withdrawFromStrategyWaitingForRemoval(address strategy) external returns (uint256);

    function getStrategiesWaitingForRemoval() external view returns (address[] memory);

    function getAllocatedToStrategyWaitingForRemoval(address strategy)
        external
        view
        returns (uint256);

    function withdraw(uint256 amount) external returns (bool);

    function initializeStrategy(address strategy_) external returns (bool);

    function withdrawAll() external;

    function withdrawFromReserve(uint256 amount) external;

    function getTotalUnderlying() external view returns (uint256);

    function getUnderlying() external view returns (address);

    function deposit() external payable;

    event StrategyActivated(address indexed strategy);

    event StrategyDeactivated(address indexed strategy);

    event NewStrategist(address indexed strategist);

    /**
     * @dev 'netProfit' is the profit after all fees have been deducted
     */
    event Harvest(uint256 indexed netProfit, uint256 indexed loss);
}
