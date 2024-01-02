// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./ConfiguratorInputTypes.sol";

/**
 * @title IPoolConfigurator
 *
 * @notice Defines the basic interface for a Pool configurator.
 */
interface IPoolConfigurator {
    /**
     * @dev Emitted when a reserve is initialized.
     * @param asset The address of the underlying asset of the reserve
     * @param yToken The address of the associated yToken contract
     * @param variableDebtToken The address of the associated variable rate debt token
     * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
     */
    event ReserveInitialized(
        address indexed asset, address indexed yToken, address variableDebtToken, address interestRateStrategyAddress
    );

    /**
     * @dev Emitted when a ERC1155 reserve is initialized.
     * @param asset The address of the underlying asset of the reserve
     * @param nToken The address of the associated yToken contract
     */
    event ERC1155ReserveInitialized(address indexed asset, address indexed nToken);

    /**
     * @dev Emitted when borrowing is enabled or disabled on a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param enabled True if borrowing is enabled, false otherwise
     */
    event ReserveBorrowing(address indexed asset, bool enabled);

    /**
     * @dev Emitted when flashloans are enabled or disabled on a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param enabled True if flashloans are enabled, false otherwise
     */
    event ReserveFlashLoaning(address indexed asset, bool enabled);

    /**
     * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
     * @param asset The address of the underlying asset of the reserve
     * @param ltv The loan to value of the asset when used as collateral
     * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
     * @param liquidationBonus The bonus liquidators receive to liquidate this asset
     */
    event CollateralConfigurationChanged(
        address indexed asset, uint256 ltv, uint256 liquidationThreshold, uint256 liquidationBonus
    );

    /**
     * @dev Emitted when a reserve is activated or deactivated
     * @param asset The address of the underlying asset of the reserve
     * @param active True if reserve is active, false otherwise
     */
    event ReserveActive(address indexed asset, bool active);

    /**
     * @dev Emitted when a reserve is frozen or unfrozen
     * @param asset The address of the underlying asset of the reserve
     * @param frozen True if reserve is frozen, false otherwise
     */
    event ReserveFrozen(address indexed asset, bool frozen);

    /**
     * @dev Emitted when a reserve is paused or unpaused
     * @param asset The address of the underlying asset of the reserve
     * @param paused True if reserve is paused, false otherwise
     */
    event ReservePaused(address indexed asset, bool paused);

    /**
     * @dev Emitted when a reserve is dropped.
     * @param asset The address of the underlying asset of the reserve
     */
    event ReserveDropped(address indexed asset);

    /**
     * @dev Emitted when a ERC1155 reserve is dropped.
     * @param asset The address of the underlying asset of the reserve
     */
    event ERC1155ReserveDropped(address indexed asset);

    /**
     * @dev Emitted when a reserve factor is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldReserveFactor The old reserve factor, expressed in bps
     * @param newReserveFactor The new reserve factor, expressed in bps
     */
    event ReserveFactorChanged(address indexed asset, uint256 oldReserveFactor, uint256 newReserveFactor);

    /**
     * @dev Emitted when the borrow cap of a reserve is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldBorrowCap The old borrow cap
     * @param newBorrowCap The new borrow cap
     */
    event BorrowCapChanged(address indexed asset, uint256 oldBorrowCap, uint256 newBorrowCap);

    /**
     * @dev Emitted when the supply cap of a reserve is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldSupplyCap The old supply cap
     * @param newSupplyCap The new supply cap
     */
    event SupplyCapChanged(address indexed asset, uint256 oldSupplyCap, uint256 newSupplyCap);

    /**
     * @dev Emitted when the liquidation protocol fee of a reserve is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldFee The old liquidation protocol fee, expressed in bps
     * @param newFee The new liquidation protocol fee, expressed in bps
     */
    event LiquidationProtocolFeeChanged(address indexed asset, uint256 oldFee, uint256 newFee);

    /**
     * @dev Emitted when the liquidation protocol fee of a reserve is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldFee The old liquidation protocol fee, expressed in bps
     * @param newFee The new liquidation protocol fee, expressed in bps
     */
    event ERC1155LiquidationProtocolFeeChanged(address indexed asset, uint256 oldFee, uint256 newFee);

    /**
     * @dev Emitted when a reserve interest strategy contract is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldStrategy The address of the old interest strategy contract
     * @param newStrategy The address of the new interest strategy contract
     */
    event ReserveInterestRateStrategyChanged(address indexed asset, address oldStrategy, address newStrategy);

    /**
     * @dev Emitted when a ERC1155 reserve configuration provider contract is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldProvider The address of the old configuration provider contract
     * @param newProvider The address of the new configuration provider contract
     */
    event ERC1155ReserveConfigurationProviderChanged(address indexed asset, address oldProvider, address newProvider);

    /**
     * @dev Emitted when an yToken implementation is upgraded.
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The yToken proxy address
     * @param implementation The new yToken implementation
     */
    event YTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

    /**
     * @dev Emitted when an nToken implementation is upgraded.
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The nToken proxy address
     * @param implementation The new nToken implementation
     */
    event NTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

    /**
     * @dev Emitted when the implementation of a variable debt token is upgraded.
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The variable debt token proxy address
     * @param implementation The new yToken implementation
     */
    event VariableDebtTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

    /**
     * @dev Emitted when the total premium on flashloans is updated.
     * @param oldFlashloanPremiumTotal The old premium, expressed in bps
     * @param newFlashloanPremiumTotal The new premium, expressed in bps
     */
    event FlashloanPremiumTotalUpdated(uint128 oldFlashloanPremiumTotal, uint128 newFlashloanPremiumTotal);

    /**
     * @dev Emitted when the part of the premium that goes to protocol is updated.
     * @param oldFlashloanPremiumToProtocol The old premium, expressed in bps
     * @param newFlashloanPremiumToProtocol The new premium, expressed in bps
     */
    event FlashloanPremiumToProtocolUpdated(
        uint128 oldFlashloanPremiumToProtocol, uint128 newFlashloanPremiumToProtocol
    );

    /**
     * @dev Emitted when the maximum number of ERC1155 collateral reserves a user can have is updated.
     * @param oldMaxERC1155CollateralReserves The old maximum number of ERC1155 collateral reserves
     * @param newMaxERC1155CollateralReserves The new maximum number of ERC1155 collateral reserves
     */
    event MaxERC1155CollateralReservesUpdated(
        uint256 oldMaxERC1155CollateralReserves, uint256 newMaxERC1155CollateralReserves
    );

    /**
     * @notice Initializes multiple reserves.
     * @param input The array of initialization parameters
     */
    function initReserves(ConfiguratorInputTypes.InitReserveInput[] calldata input) external;

    /**
     * @notice Initializes multiple reserves.
     * @param input The array of initialization parameters
     */
    function initERC1155Reserves(ConfiguratorInputTypes.InitERC1155ReserveInput[] calldata input) external;

    /**
     * @dev Updates the yToken implementation for the reserve.
     * @param input The yToken update parameters
     */
    function updateYToken(ConfiguratorInputTypes.UpdateYTokenInput calldata input) external;

    /**
     * @dev Updates the nToken implementation for the reserve.
     * @param input The nToken update parameters
     */
    function updateNToken(ConfiguratorInputTypes.UpdateNTokenInput calldata input) external;

    /**
     * @notice Updates the variable debt token implementation for the asset.
     * @param input The variableDebtToken update parameters
     */
    function updateVariableDebtToken(ConfiguratorInputTypes.UpdateDebtTokenInput calldata input) external;

    /**
     * @notice Configures borrowing on a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param enabled True if borrowing needs to be enabled, false otherwise
     */
    function setReserveBorrowing(address asset, bool enabled) external;

    /**
     * @notice Configures the reserve collateralization parameters.
     * @dev All the values are expressed in bps. A value of 10000, results in 100.00%
     * @dev The `liquidationBonus` is always above 100%. A value of 105% means the liquidator will receive a 5% bonus
     * @param asset The address of the underlying asset of the reserve
     * @param ltv The loan to value of the asset when used as collateral
     * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
     * @param liquidationBonus The bonus liquidators receive to liquidate this asset
     */
    function configureReserveAsCollateral(
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external;

    /**
     * @notice Enable or disable flashloans on a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param enabled True if flashloans need to be enabled, false otherwise
     */
    function setReserveFlashLoaning(address asset, bool enabled) external;

    /**
     * @notice Activate or deactivate a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param active True if the reserve needs to be active, false otherwise
     */
    function setReserveActive(address asset, bool active) external;

    /**
     * @notice Freeze or unfreeze a reserve. A frozen reserve doesn't allow any new supply, borrow
     * or rate swap but allows repayments, liquidations, rate rebalances and withdrawals.
     * @param asset The address of the underlying asset of the reserve
     * @param freeze True if the reserve needs to be frozen, false otherwise
     */
    function setReserveFreeze(address asset, bool freeze) external;

    /**
     * @notice Pauses a reserve. A paused reserve does not allow any interaction (supply, borrow, repay,
     * swap interest rate, liquidate, ytoken transfers).
     * @param asset The address of the underlying asset of the reserve
     * @param paused True if pausing the reserve, false if unpausing
     */
    function setReservePause(address asset, bool paused) external;

    /**
     * @notice Updates the reserve factor of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newReserveFactor The new reserve factor of the reserve
     */
    function setReserveFactor(address asset, uint256 newReserveFactor) external;

    /**
     * @notice Sets the interest rate strategy of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newRateStrategyAddress The address of the new interest strategy contract
     */
    function setReserveInterestRateStrategyAddress(address asset, address newRateStrategyAddress) external;

    /**
     * @notice Sets the configuration provider of a ERC1155 reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newConfigurationProvider The address of the new configuration provider contract
     */
    function setERC1155ReserveConfigurationProvider(address asset, address newConfigurationProvider) external;

    /**
     * @notice Pauses or unpauses all the protocol reserves. In the paused state all the protocol interactions
     * are suspended.
     * @param paused True if protocol needs to be paused, false otherwise
     */
    function setPoolPause(bool paused) external;

    /**
     * @notice Updates the borrow cap of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newBorrowCap The new borrow cap of the reserve
     */
    function setBorrowCap(address asset, uint256 newBorrowCap) external;

    /**
     * @notice Updates the supply cap of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newSupplyCap The new supply cap of the reserve
     */
    function setSupplyCap(address asset, uint256 newSupplyCap) external;

    /**
     * @notice Updates the liquidation protocol fee of reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newFee The new liquidation protocol fee of the reserve, expressed in bps
     */
    function setLiquidationProtocolFee(address asset, uint256 newFee) external;

    /**
     * @notice Updates the liquidation protocol fee of ERC1155 reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newFee The new liquidation protocol fee of the reserve, expressed in bps
     */
    function setERC1155LiquidationProtocolFee(address asset, uint256 newFee) external;

    /**
     * @notice Drops a reserve entirely.
     * @param asset The address of the reserve to drop
     */
    function dropReserve(address asset) external;

    /**
     * @notice Drops a ERC1155 reserve entirely.
     * @param asset The address of the reserve to drop
     */
    function dropERC1155Reserve(address asset) external;

    /**
     * @notice Updates the total flash loan premium.
     * Total flash loan premium consists of two parts:
     * - A part is sent to yToken holders as extra balance
     * - A part is collected by the protocol reserves
     * @dev Expressed in bps
     * @dev The premium is calculated on the total amount borrowed
     * @param newFlashloanPremiumTotal The total flashloan premium
     */
    function updateFlashloanPremiumTotal(uint128 newFlashloanPremiumTotal) external;

    /**
     * @notice Updates the flash loan premium collected by protocol reserves
     * @dev Expressed in bps
     * @dev The premium to protocol is calculated on the total flashloan premium
     * @param newFlashloanPremiumToProtocol The part of the flashloan premium sent to the protocol treasury
     */
    function updateFlashloanPremiumToProtocol(uint128 newFlashloanPremiumToProtocol) external;

    /**
     * @notice Updates the maximum count of ERC1155 collateral reserves a user can have
     * @param newMaxERC1155CollateralReserves The count of ERC1155 collateral reserves
     */
    function updateMaxERC1155CollateralReserves(uint256 newMaxERC1155CollateralReserves) external;
}
