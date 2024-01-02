// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

import "./UtilLib.sol";
import "./LRTConstants.sol";
import "./LRTConfigRoleChecker.sol";

import "./INodeDelegator.sol";
import "./IStrategy.sol";
import "./IEigenStrategyManager.sol";

import "./IERC20.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

/// @title NodeDelegator Contract
/// @notice The contract that handles the depositing of assets into strategies
contract NodeDelegator is INodeDelegator, LRTConfigRoleChecker, PausableUpgradeable, ReentrancyGuardUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract
    /// @param lrtConfigAddr LRT config address
    function initialize(address lrtConfigAddr) external initializer {
        UtilLib.checkNonZeroAddress(lrtConfigAddr);
        __Pausable_init();
        __ReentrancyGuard_init();

        lrtConfig = ILRTConfig(lrtConfigAddr);
        emit UpdatedLRTConfig(lrtConfigAddr);
    }

    /// @notice Approves the maximum amount of an asset to the eigen strategy manager
    /// @dev only supported assets can be deposited and only called by the LRT manager
    /// @param asset the asset to deposit
    function maxApproveToEigenStrategyManager(address asset)
        external
        override
        onlySupportedAsset(asset)
        onlyLRTManager
    {
        address eigenlayerStrategyManagerAddress = lrtConfig.getContract(LRTConstants.EIGEN_STRATEGY_MANAGER);
        IERC20(asset).approve(eigenlayerStrategyManagerAddress, type(uint256).max);
    }

    /// @notice Deposits an asset lying in this NDC into its strategy
    /// @dev only supported assets can be deposited and only called by the LRT manager
    /// @param asset the asset to deposit
    function depositAssetIntoStrategy(address asset)
        external
        override
        whenNotPaused
        nonReentrant
        onlySupportedAsset(asset)
        onlyLRTManager
    {
        address strategy = lrtConfig.assetStrategy(asset);
        if (strategy == address(0)) {
            revert StrategyIsNotSetForAsset();
        }

        IERC20 token = IERC20(asset);
        address eigenlayerStrategyManagerAddress = lrtConfig.getContract(LRTConstants.EIGEN_STRATEGY_MANAGER);

        uint256 balance = token.balanceOf(address(this));

        emit AssetDepositIntoStrategy(asset, strategy, balance);

        IEigenStrategyManager(eigenlayerStrategyManagerAddress).depositIntoStrategy(IStrategy(strategy), token, balance);
    }

    /// @notice Transfers an asset back to the LRT deposit pool
    /// @dev only supported assets can be transferred and only called by the LRT manager
    /// @param asset the asset to transfer
    /// @param amount the amount to transfer
    function transferBackToLRTDepositPool(
        address asset,
        uint256 amount
    )
        external
        whenNotPaused
        nonReentrant
        onlySupportedAsset(asset)
        onlyLRTManager
    {
        address lrtDepositPool = lrtConfig.getContract(LRTConstants.LRT_DEPOSIT_POOL);

        if (!IERC20(asset).transfer(lrtDepositPool, amount)) {
            revert TokenTransferFailed();
        }
    }

    /// @notice Fetches balance of all assets staked in eigen layer through this contract
    /// @return assets the assets that the node delegator has deposited into strategies
    /// @return assetBalances the balances of the assets that the node delegator has deposited into strategies
    function getAssetBalances()
        external
        view
        override
        returns (address[] memory assets, uint256[] memory assetBalances)
    {
        address eigenlayerStrategyManagerAddress = lrtConfig.getContract(LRTConstants.EIGEN_STRATEGY_MANAGER);

        (IStrategy[] memory strategies,) =
            IEigenStrategyManager(eigenlayerStrategyManagerAddress).getDeposits(address(this));

        uint256 strategiesLength = strategies.length;
        assets = new address[](strategiesLength);
        assetBalances = new uint256[](strategiesLength);

        for (uint256 i = 0; i < strategiesLength;) {
            assets[i] = address(IStrategy(strategies[i]).underlyingToken());
            assetBalances[i] = IStrategy(strategies[i]).userUnderlyingView(address(this));
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Returns the balance of an asset that the node delegator has deposited into the strategy
    /// @param asset the asset to get the balance of
    /// @return stakedBalance the balance of the asset
    function getAssetBalance(address asset) external view override returns (uint256) {
        address strategy = lrtConfig.assetStrategy(asset);
        if (strategy == address(0)) {
            return 0;
        }

        return IStrategy(strategy).userUnderlyingView(address(this));
    }

    /// @dev Triggers stopped state. Contract must not be paused.
    function pause() external onlyLRTManager {
        _pause();
    }

    /// @dev Returns to normal state. Contract must be paused
    function unpause() external onlyLRTAdmin {
        _unpause();
    }
}
