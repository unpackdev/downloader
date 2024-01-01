// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "./DataTypes.sol";

interface IKyokoPoolConfigurator {
    /**
     * @dev Emitted when a reserve is initialized.
     * @param reserveId The id of the reserve
     * @param asset The address of the underlying nft asset of the reserve
     * @param kToken The address of the associated kToken contract
     * @param stableDebtToken The address of the associated stable rate debt token
     * @param variableDebtToken The address of the associated variable rate debt token
     * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
     **/
    event ReserveInitialized(
        uint256 indexed reserveId,
        address indexed asset,
        address indexed kToken,
        address stableDebtToken,
        address variableDebtToken,
        address interestRateStrategyAddress
    );

    /**
     * @dev Emitted when a reserve is activated
     * @param reserveId The id of the reserve
     **/
    event ReserveActivated(uint256 indexed reserveId);

    /**
     * @dev Emitted when a reserve is deactivated
     * @param reserveId The id of the reserve
     **/
    event ReserveDeactivated(uint256 indexed reserveId);

    /**
     * @dev Emitted when a reserve is frozen
     * @param reserveId The id of the reserve
     **/
    event ReserveFrozen(uint256 indexed reserveId);

    /**
     * @dev Emitted when a reserve is unfrozen
     * @param reserveId The id of the reserve
     **/
    event ReserveUnfrozen(uint256 indexed reserveId);

    /**
     * @dev Emitted when a reserve factor is updated
     * @param reserveId The id of the reserve
     * @param factor The new reserve factor
     **/
    event ReserveFactorChanged(uint256 indexed reserveId, uint256 factor);

    /**
     * @dev Emitted when a borrow ratio is updated
     * @param reserveId The id of the reserve
     * @param ratio The new borrow ratio
     **/
    event ReserveBorrowRatioChanged(uint256 indexed reserveId, uint256 ratio);

    /**
     * @dev Emitted when a fixed borrow perdio is updated
     * @param reserveId The id of the reserve
     * @param period The new fixed borrow period
     **/
    event ReservePeriodChanged(uint256 indexed reserveId, uint256 period);

    /**
     * @dev Emitted when a fixed borrow perdio is updated
     * @param reserveId The id of the reserve
     * @param time The new minimum borrow time
     **/
    event ReserveMinBorrowTimeChanged(uint256 indexed reserveId, uint256 time);

    /**
     * @dev Emitted when borrowing is enabled on a reserve
     * @param reserveId The id of the reserve
     * @param stableRateEnabled True if stable rate borrowing is enabled, false otherwise
     **/
    event BorrowingEnabledOnReserve(
        uint256 indexed reserveId,
        bool stableRateEnabled
    );

    /**
     * @dev Emitted when borrowing is disabled on a reserve
     * @param reserveId The id of the reserve
     **/
    event BorrowingDisabledOnReserve(uint256 indexed reserveId);

    /**
     * @dev Emitted when stable rate borrowing is enabled on a reserve
     * @param reserveId The id of the reserve
     **/
    event StableRateEnabledOnReserve(uint256 indexed reserveId);

    /**
     * @dev Emitted when stable rate borrowing is disabled on a reserve
     * @param reserveId The id of the reserve
     **/
    event StableRateDisabledOnReserve(uint256 indexed reserveId);

    /**
     * @dev Emitted when a reserve liquidation threshold is updated
     * @param reserveId The id of the reserve
     * @param threshold The new liquidation threshold of the reserve
     **/
    event ReserveLiquidationThresholdChanged(
        uint256 indexed reserveId,
        uint256 threshold
    );

    /**
     * @dev Emitted when a reserve liquidation duration is updated
     * @param reserveId The id of the reserve
     * @param duration The duration of the liquidation
     **/
    event ReserveLiquidationDurationChanged(
        uint256 indexed reserveId,
        uint256 duration
    );

    /**
     * @dev Emitted when a reserve bid duration is updated
     * @param reserveId The id of the reserve
     * @param duration The duration of each auction
     **/
    event ReserveBidDurationChanged(
        uint256 indexed reserveId,
        uint256 duration
    );

    /**
     * @dev Emitted when a reserve initial liquidity lock time is updated
     * @param reserveId The id of the reserve
     * @param lockTime The lock time
     **/
    event ReserveLockTimeChanged(uint256 indexed reserveId, uint256 lockTime);

    /**
     * @dev Emitted when a reserve type is updated
     * @param reserveId The id of the reserve
     * @param reserveType The reserve type
     **/
    event ReserveTypeChanged(uint256 indexed reserveId, uint256 reserveType);

    /**
     * @dev Emitted when a reserve initial liquidity is burned
     * @param reserveId The id of the reserve
     * @param amount The burned amount
     **/
    event ReserveInitialLiquidityBurned(
        uint256 indexed reserveId,
        uint256 amount
    );

    /**
     * @dev Emitted when a reserve interest strategy contract is updated
     * @param reserveId The id of the reserve
     * @param strategy The new address of the interest strategy contract
     **/
    event ReserveInterestRateStrategyChanged(
        uint256 indexed reserveId,
        address strategy
    );

    /**
     * @dev Emitted when an kToken implementation is upgraded
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The kToken proxy address
     * @param implementation The new kToken implementation
     **/
    event kTokenUpgraded(
        address indexed asset,
        address indexed proxy,
        address indexed implementation
    );

    /**
     * @dev Emitted when the implementation of a stable debt token is upgraded
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The stable debt token proxy address
     * @param implementation The new kToken implementation
     **/
    event StableDebtTokenUpgraded(
        address indexed asset,
        address indexed proxy,
        address indexed implementation
    );

    /**
     * @dev Emitted when the implementation of a variable debt token is upgraded
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The variable debt token proxy address
     * @param implementation The new kToken implementation
     **/
    event VariableDebtTokenUpgraded(
        address indexed asset,
        address indexed proxy,
        address indexed implementation
    );

    function factoryInitReserve(
        DataTypes.InitReserveInput memory input,
        DataTypes.RateStrategyInput memory rateInput
    ) external;
}
