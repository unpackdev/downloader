// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "./ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ReserveConfiguration.sol";
import "./DataTypes.sol";
import "./PercentageMath.sol";
import "./Errors.sol";
import "./IKyokoPool.sol";
import "./IKyokoFactory.sol";
import "./IKyokoPoolAddressesProvider.sol";
import "./IKyokoPoolConfigurator.sol";
import "./IInterestRateStrategy.sol";
import "./IWETH.sol";

/**
 * @title KyokoPoolConfigurator contract
 * @author Kyoko
 * @dev Implements the configuration methods for the Kyoko protocol
 **/

contract KyokoPoolConfigurator is IKyokoPoolConfigurator, ContextUpgradeable {
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    IKyokoPoolAddressesProvider internal _addressesProvider;
    IKyokoPool internal _pool;
    IWETH internal WETH;
    IKyokoFactory internal _factory;
    IInterestRateStrategy internal _rate;

    modifier onlyPoolAdmin() {
        require(
            _addressesProvider.isAdmin(_msgSender()),
            Errors.CALLER_NOT_POOL_ADMIN
        );
        _;
    }

    modifier onlyEmergencyAdmin() {
        require(
            _addressesProvider.isEmergencyAdmin(_msgSender()),
            Errors.KPC_CALLER_NOT_EMERGENCY_ADMIN
        );
        _;
    }

    modifier onlyFactory() {
        require(
            _addressesProvider.isFactory(_msgSender()),
            Errors.KPC_CALLER_NOT_EMERGENCY_ADMIN
        );
        _;
    }

    uint256 internal constant CONFIGURATOR_REVISION = 0x1;

    function initialize(IKyokoPoolAddressesProvider provider, address weth)
        public
        initializer
    {
        _addressesProvider = provider;
        WETH = IWETH(weth);
        _pool = IKyokoPool(_addressesProvider.getKyokoPool()[0]);
        _rate = IInterestRateStrategy(_addressesProvider.getRateStrategy()[0]);
        _factory = IKyokoFactory(_addressesProvider.getKyokoPoolFactory()[0]);
    }

    function updatePool() external onlyPoolAdmin {
        _pool = IKyokoPool(_addressesProvider.getKyokoPool()[0]);
    }

    function updateRate() external onlyPoolAdmin {
        _rate = IInterestRateStrategy(_addressesProvider.getRateStrategy()[0]);
    }

    function updateFactory() external onlyPoolAdmin {
        _factory = IKyokoFactory(_addressesProvider.getKyokoPoolFactory()[0]);
    }

    /**
     * @dev Initializes reserves in batch
     **/
    function batchInitReserve(
        DataTypes.InitReserveInput[] memory input,
        DataTypes.RateStrategyInput[] memory rateInput
    ) external onlyPoolAdmin {
        IKyokoPool cachedPool = _pool;
        IInterestRateStrategy cachedRate = _rate;
        for (uint256 i = 0; i < input.length; i++) {
            _initReserve(cachedPool, input[i]);
            _initRate(cachedRate, rateInput[i]);
        }
    }

    function factoryInitReserve(
        DataTypes.InitReserveInput memory input,
        DataTypes.RateStrategyInput memory rateInput
    ) external override onlyFactory {
        IKyokoPool cachedPool = _pool;
        IInterestRateStrategy cachedRate = _rate;
        _initReserve(cachedPool, input);
        _initRate(cachedRate, rateInput);
    }

    function _initReserve(
        IKyokoPool pool,
        DataTypes.InitReserveInput memory input
    ) internal {
        pool.initReserve(
            input.underlyingAsset,
            input.kTokenImpl,
            input.stableDebtTokenImpl,
            input.variableDebtTokenImpl,
            input.interestRateStrategyAddress
        );

        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(input.reserveId);

        currentConfig.setReserveFactor(input.factor);

        currentConfig.setBorrowRatio(input.borrowRatio);

        currentConfig.setPeriod(input.period);

        currentConfig.setMinBorrowTime(input.minBorrowTime);

        currentConfig.setActive(true);
        currentConfig.setFrozen(false);
        currentConfig.setBorrowingEnabled(true);
        currentConfig.setStableRateBorrowingEnabled(input.stableBorrowed);

        currentConfig.setLiquidationThreshold(input.liqThreshold);
        currentConfig.setLiquidationTime(input.liqDuration);
        currentConfig.setBidTime(input.bidDuration);
        currentConfig.setLockTime(input.lockTime);

        _pool.setConfiguration(input.reserveId, currentConfig.data);

        emit ReserveInitialized(
            input.reserveId,
            input.underlyingAsset,
            input.kTokenImpl,
            input.stableDebtTokenImpl,
            input.variableDebtTokenImpl,
            input.interestRateStrategyAddress
        );
    }

    function _initRate(
        IInterestRateStrategy rate,
        DataTypes.RateStrategyInput memory input
    ) internal {
        rate.setRate(
            input.reserveId,
            input.optimalUtilizationRate,
            input.baseVariableBorrowRate,
            input.variableSlope1,
            input.variableSlope2,
            input.baseStableBorrowRate,
            input.stableSlope1,
            input.stableSlope2
        );
    }

    /**
     * @dev Activates a reserve
     * @param reserveId The id of the reserve
     **/
    function activateReserve(uint256 reserveId) external onlyPoolAdmin {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);

        currentConfig.setActive(true);

        _pool.setConfiguration(reserveId, currentConfig.data);

        emit ReserveActivated(reserveId);
    }

    /**
     * @dev Deactivates a reserve
     * @param reserveId The id of the reserve
     **/
    function deactivateReserve(uint256 reserveId) external onlyPoolAdmin {
        _checkNoLiquidity(reserveId);

        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);

        currentConfig.setActive(false);

        _pool.setConfiguration(reserveId, currentConfig.data);

        emit ReserveDeactivated(reserveId);
    }

    /**
     * @dev Freezes a reserve. A frozen reserve doesn't allow any new deposit, borrow
     *  but allows repayments, liquidations, rate rebalances and withdrawals
     * @param reserveId The id of the reserve
     **/
    function freezeReserve(uint256 reserveId) external onlyPoolAdmin {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);

        currentConfig.setFrozen(true);

        _pool.setConfiguration(reserveId, currentConfig.data);

        emit ReserveFrozen(reserveId);
    }

    /**
     * @dev Unfreezes a reserve
     * @param reserveId The id of the reserve
     **/
    function unfreezeReserve(uint256 reserveId) external onlyPoolAdmin {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);

        currentConfig.setFrozen(false);

        _pool.setConfiguration(reserveId, currentConfig.data);

        emit ReserveUnfrozen(reserveId);
    }

    /**
     * @dev Updates the reserve factor of a reserve
     * @param reserveId The id of the reserve
     * @param reserveFactor The new reserve factor of the reserve
     **/
    function setReserveFactor(uint256 reserveId, uint256 reserveFactor)
        external
        onlyPoolAdmin
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);

        currentConfig.setReserveFactor(reserveFactor);

        _pool.setConfiguration(reserveId, currentConfig.data);

        emit ReserveFactorChanged(reserveId, reserveFactor);
    }

    /**
     * @dev Updates the borrow ratio of a reserve
     * @param reserveId The id of the reserve
     * @param ratio The new borrow ratio of the reserve
     **/
    function setBorrowRatio(uint256 reserveId, uint256 ratio)
        external
        onlyPoolAdmin
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);

        currentConfig.setBorrowRatio(ratio);

        _pool.setConfiguration(reserveId, currentConfig.data);

        emit ReserveBorrowRatioChanged(reserveId, ratio);
    }

    /**
     * @dev Updates the borrow ratio of a reserve
     * @param reserveId The id of the reserve
     * @param period The new fixed borrow period of the reserve
     **/
    function setPeriod(uint256 reserveId, uint256 period)
        external
        onlyPoolAdmin
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);

        currentConfig.setPeriod(period);

        _pool.setConfiguration(reserveId, currentConfig.data);

        emit ReservePeriodChanged(reserveId, period);
    }

    /**
     * @dev Updates the borrow ratio of a reserve
     * @param reserveId The id of the reserve
     * @param time The new minimum borrow time
     **/
    function setMinBorrowTime(uint256 reserveId, uint256 time)
        external
        onlyPoolAdmin
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);

        currentConfig.setMinBorrowTime(time);

        _pool.setConfiguration(reserveId, currentConfig.data);

        emit ReserveMinBorrowTimeChanged(reserveId, time);
    }

    /**
     * @dev Enables borrowing on a reserve
     * @param reserveId The id of the reserve
     * @param stableBorrowRateEnabled True if stable borrow rate needs to be enabled by default on this reserve
     **/
    function enableBorrowingOnReserve(
        uint256 reserveId,
        bool stableBorrowRateEnabled
    ) external onlyPoolAdmin {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);

        currentConfig.setBorrowingEnabled(true);
        currentConfig.setStableRateBorrowingEnabled(stableBorrowRateEnabled);

        _pool.setConfiguration(reserveId, currentConfig.data);

        emit BorrowingEnabledOnReserve(reserveId, stableBorrowRateEnabled);
    }

    /**
     * @dev Disables borrowing on a reserve
     * @param reserveId The id of the reserve
     **/
    function disableBorrowingOnReserve(uint256 reserveId)
        external
        onlyPoolAdmin
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);

        currentConfig.setBorrowingEnabled(false);

        _pool.setConfiguration(reserveId, currentConfig.data);
        emit BorrowingDisabledOnReserve(reserveId);
    }

    /**
     * @dev Enable stable rate borrowing on a reserve
     * @param reserveId The id of the reserve
     **/
    function enableReserveStableRate(uint256 reserveId) external onlyPoolAdmin {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);

        currentConfig.setStableRateBorrowingEnabled(true);

        _pool.setConfiguration(reserveId, currentConfig.data);

        emit StableRateEnabledOnReserve(reserveId);
    }

    /**
     * @dev Disable stable rate borrowing on a reserve
     * @param reserveId The id of the reserve
     **/
    function disableReserveStableRate(uint256 reserveId)
        external
        onlyPoolAdmin
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);

        currentConfig.setStableRateBorrowingEnabled(false);

        _pool.setConfiguration(reserveId, currentConfig.data);

        emit StableRateDisabledOnReserve(reserveId);
    }

    /**
     * @dev Sets the liquidation threshold of a reserve
     * @param reserveId The id of the reserve
     * @param threshold The new liquidation threshold of the reserve
     **/
    function setLiquidationThreshold(uint256 reserveId, uint256 threshold)
        external
        onlyPoolAdmin
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);
        currentConfig.setLiquidationThreshold(threshold);
        _pool.setConfiguration(reserveId, currentConfig.data);
        emit ReserveLiquidationThresholdChanged(reserveId, threshold);
    }

    /**
     * @dev Sets the liquidation duration of a reserve
     * @param reserveId The id of the reserve
     * @param duration The new liquidation duration of the reserve
     **/
    function setLiquidationDuration(uint256 reserveId, uint256 duration)
        external
        onlyPoolAdmin
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);
        currentConfig.setLiquidationTime(duration);
        _pool.setConfiguration(reserveId, currentConfig.data);
        emit ReserveLiquidationDurationChanged(reserveId, duration);
    }

    /**
     * @dev Sets the bid duration of a reserve
     * @param reserveId The id of the reserve
     * @param duration The new bid duration of the reserve
     **/
    function setBidDuration(uint256 reserveId, uint256 duration)
        external
        onlyPoolAdmin
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);
        currentConfig.setBidTime(duration);
        _pool.setConfiguration(reserveId, currentConfig.data);
        emit ReserveBidDurationChanged(reserveId, duration);
    }

    /**
     * @dev Sets the lock time of initial liquidity
     * @param reserveId The id of the reserve
     * @param lockTime The new lock time
     **/
    function setLockTime(uint256 reserveId, uint256 lockTime)
        external
        onlyPoolAdmin
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);
        currentConfig.setLockTime(lockTime);
        _pool.setConfiguration(reserveId, currentConfig.data);
        emit ReserveLockTimeChanged(reserveId, lockTime);
    }

    /**
     * @dev Sets the type of reserve, 0 for perimissionless poo, 1 for blue chip, others for middle pool
     * @param reserveId The id of the reserve
     * @param reserveType The new reserve type
     **/
    function setType(uint256 reserveId, uint256 reserveType)
        external
        onlyPoolAdmin
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(reserveId);
        currentConfig.setType(reserveType);
        _pool.setConfiguration(reserveId, currentConfig.data);
        emit ReserveTypeChanged(reserveId, reserveType);
    }

    /**
     * @dev Sets the interest rate strategy of a reserve
     * @param reserveId The id of the reserve
     * @param rateStrategyAddress The new address of the interest strategy contract
     **/
    function setReserveInterestRateStrategyAddress(
        uint256 reserveId,
        address rateStrategyAddress
    ) external onlyPoolAdmin {
        _pool.setReserveInterestRateStrategyAddress(
            reserveId,
            rateStrategyAddress
        );
        emit ReserveInterestRateStrategyChanged(reserveId, rateStrategyAddress);
    }

    /**
     * @dev pauses or unpauses all the actions of the protocol, including kToken transfers
     * @param val true if protocol needs to be paused, false otherwise
     **/
    function setPoolPause(bool val) external onlyEmergencyAdmin {
        _pool.setPause(val);
    }

    function updateNFT(
        uint256 reserveId,
        address asset,
        bool flag
    ) external onlyPoolAdmin {
        _pool.updateReserveNFT(reserveId, asset, flag);
    }

    function setKyokoFactoryFactor(uint16 factor) external onlyPoolAdmin {
        _factory.setFactor(factor);
    }

    function setKyokoFactoryInitialLiquidity(uint256 amount)
        external
        onlyPoolAdmin
    {
        _factory.setInitialLiquidity(amount);
    }

    function setKyokoFactoryLiquidationThreshold(uint16 threshold)
        external
        onlyPoolAdmin
    {
        _factory.setLiqThreshold(threshold);
    }

    function setKyokoFactoryLockTime(uint32 lockTime) external onlyPoolAdmin {
        _factory.setLockTime(lockTime);
    }

    function setTokenFactory(address createKToken, address createDebtToken)
        external
        onlyPoolAdmin
    {
        _factory.setTokenFactory(createKToken, createDebtToken);
    }

    function setVariableRate(
        uint256 reserveId,
        uint256 _baseVariableRate,
        uint256 _variableSlope1,
        uint256 _variableSlope2
    ) external onlyPoolAdmin {
        IInterestRateStrategy rate = _rate;
        rate.setVariableRate(
            reserveId,
            _baseVariableRate,
            _variableSlope1,
            _variableSlope2
        );
    }

    function setStableRate(
        uint256 reserveId,
        uint256 _baseStableRate,
        uint256 _stableSlope1,
        uint256 _stableSlope2
    ) external onlyPoolAdmin {
        IInterestRateStrategy rate = _rate;
        rate.setStableRate(
            reserveId,
            _baseStableRate,
            _stableSlope1,
            _stableSlope2
        );
    }

    function _checkNoLiquidity(uint256 reserveId) internal view {
        DataTypes.ReserveData memory reserveData = _pool.getReserveData(
            reserveId
        );
        address kToken = reserveData.kTokenAddress;
        uint256 availableLiquidity = IERC20Upgradeable(address(WETH)).balanceOf(
            kToken
        );

        require(
            availableLiquidity == 0 && reserveData.currentLiquidityRate == 0,
            Errors.KPC_RESERVE_LIQUIDITY_NOT_0
        );
    }
}
