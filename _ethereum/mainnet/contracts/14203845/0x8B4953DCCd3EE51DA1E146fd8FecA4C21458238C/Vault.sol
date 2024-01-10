// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "SafeERC20.sol";
import "Initializable.sol";
import "IERC20.sol";

import "ILiquidityPool.sol";
import "IVault.sol";
import "IVaultReserve.sol";
import "IController.sol";
import "IStrategy.sol";

import "ScaledMath.sol";
import "Errors.sol";
import "EnumerableExtensions.sol";
import "AddressProviderHelpers.sol";

import "VaultStorage.sol";
import "Preparable.sol";
import "IPausable.sol";
import "AdminUpgradeable.sol";

abstract contract Vault is IVault, AdminUpgradeable, VaultStorageV1, Preparable, Initializable {
    using ScaledMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableExtensions for EnumerableSet.AddressSet;
    using EnumerableMapping for EnumerableMapping.AddressToUintMap;
    using EnumerableExtensions for EnumerableMapping.AddressToUintMap;
    using AddressProviderHelpers for IAddressProvider;

    bytes32 internal constant _STRATEGY_KEY = "Strategy";
    bytes32 internal constant _PERFORMANCE_FEE_KEY = "PerformanceFee";
    bytes32 internal constant _STRATEGIST_FEE_KEY = "StrategistFee";
    bytes32 internal constant _DEBT_LIMIT_KEY = "DebtLimit";
    bytes32 internal constant _TARGET_ALLOCATION_KEY = "TargetAllocation";
    bytes32 internal constant _RESERVE_FEE_KEY = "ReserveFee";
    bytes32 internal constant _BOUND_KEY = "Bound";

    uint256 internal constant _INITIAL_RESERVE_FEE = DECIMAL_SCALE / 100;
    uint256 internal constant _INITIAL_STRATEGIST_FEE = DECIMAL_SCALE / 10;
    uint256 internal constant _INITIAL_PERFORMANCE_FEE = (DECIMAL_SCALE * 5) / 100;

    uint256 public constant DECIMAL_SCALE = 1e18;
    uint256 public constant MAX_PERFORMANCE_FEE = 0.5e18;
    uint256 public constant MAX_DEVIATION_BOUND = 0.5e18;
    uint256 public constant STRATEGY_DELAY = 5 days;

    IController public immutable controller;
    IVaultReserve public immutable reserve;

    constructor(address _controller) {
        controller = IController(_controller);
        reserve = IVaultReserve(IController(_controller).addressProvider().getVaultReserve());
    }

    function initialize(
        address _pool,
        uint256 _debtLimit,
        uint256 _targetAllocation,
        uint256 _bound
    ) external virtual override initializer {
        require(_debtLimit <= DECIMAL_SCALE, Error.INVALID_AMOUNT);
        require(_targetAllocation <= DECIMAL_SCALE, Error.INVALID_AMOUNT);
        require(_bound <= MAX_DEVIATION_BOUND, Error.INVALID_AMOUNT);

        _initializeAdmin(msg.sender);
        pool = _pool;

        _setConfig(_DEBT_LIMIT_KEY, _debtLimit);
        _setConfig(_TARGET_ALLOCATION_KEY, _targetAllocation);
        _setConfig(_BOUND_KEY, _bound);
        _setConfig(_RESERVE_FEE_KEY, _INITIAL_RESERVE_FEE);
        _setConfig(_STRATEGIST_FEE_KEY, _INITIAL_STRATEGIST_FEE);
        _setConfig(_PERFORMANCE_FEE_KEY, _INITIAL_PERFORMANCE_FEE);
    }

    /**
     * @notice Handles deposits from the liquidity pool
     */
    function deposit() external payable override onlyAdmin {
        _deposit();
    }

    /**
     * @notice Withdraws specified amount of underlying from vault.
     * @dev If the specified amount exceeds idle funds, an amount of funds is withdrawn
     *      from the strategy such that it will achieve a target allocation for after the
     *      amount has been withdrawn.
     * @param amount Amount to withdraw.
     * @return `true` if successful.
     */
    function withdraw(uint256 amount) external override onlyAdmin returns (bool) {
        IStrategy strategy = getStrategy();
        uint256 availableUnderlying_ = _availableUnderlying();

        if (availableUnderlying_ < amount) {
            if (address(strategy) == address(0)) return false;
            uint256 allocated = strategy.balance();
            uint256 requiredWithdrawal = amount - availableUnderlying_;

            if (requiredWithdrawal > allocated) return false;

            // compute withdrawal amount to sustain target allocation
            uint256 newTarget = (allocated - requiredWithdrawal).scaledMul(getTargetAllocation());
            uint256 excessAmount = allocated - newTarget;
            strategy.withdraw(excessAmount);
            currentAllocated = _computeNewAllocated(currentAllocated, excessAmount);
        } else {
            uint256 allocatedUnderlying = 0;
            if (address(strategy) != address(0))
                allocatedUnderlying = IStrategy(strategy).balance();
            uint256 totalUnderlying = availableUnderlying_ +
                allocatedUnderlying +
                waitingForRemovalAllocated;
            uint256 totalUnderlyingAfterWithdraw = totalUnderlying - amount;
            _rebalance(totalUnderlyingAfterWithdraw, allocatedUnderlying);
        }

        _transfer(pool, amount);
        return true;
    }

    /**
     * @notice Withdraws all funds from vault and strategy and transfer them to the pool.
     */
    function withdrawAll() external override onlyAdmin {
        withdrawAllFromStrategy();
        uint256 balance = _availableUnderlying();
        _transfer(pool, balance);
    }

    /**
     * @notice Withdraws specified amount of underlying from reserve to vault.
     * @dev Withdraws from reserve will cause a spike in pool exchange rate.
     *  Pool deposits should be paused during this to prevent front running
     * @param amount Amount to withdraw.
     */
    function withdrawFromReserve(uint256 amount) external override onlyAdmin {
        require(amount > 0, Error.INVALID_AMOUNT);
        require(IPausable(pool).isPaused(), Error.POOL_NOT_PAUSED);
        uint256 reserveBalance_ = _reserveBalance();
        require(amount <= reserveBalance_, Error.INSUFFICIENT_BALANCE);
        reserve.withdraw(getUnderlying(), amount);
    }

    /**
     * @notice Activate the current strategy set for the vault.
     * @return `true` if strategy has been activated
     */
    function activateStrategy() external onlyAdmin returns (bool) {
        return _activateStrategy();
    }

    /**
     * @notice Deactivates a strategy.
     * @return `true` if strategy has been deactivated
     */
    function deactivateStrategy() external onlyAdmin returns (bool) {
        return _deactivateStrategy();
    }

    /**
     * @notice Initializes the vault's strategy.
     * @dev Bypasses the time delay, but can only be called if strategy is not set already.
     * @param strategy_ Address of the strategy.
     * @return `true` if successful.
     */
    function initializeStrategy(address strategy_) external override onlyAdmin returns (bool) {
        require(currentAddresses[_STRATEGY_KEY] == address(0), Error.ADDRESS_ALREADY_SET);
        require(strategy_ != address(0), Error.ZERO_ADDRESS_NOT_ALLOWED);
        _setConfig(_STRATEGY_KEY, strategy_);
        _activateStrategy();
        address strategist_ = IStrategy(strategy_).strategist();
        require(strategist_ != address(0), Error.ZERO_ADDRESS_NOT_ALLOWED);
        strategist = strategist_;
        emit NewStrategist(strategist_);
        return true;
    }

    /**
     * @notice Prepare update of the vault's strategy (with time delay enforced).
     * @param newStrategy Address of the new strategy.
     * @return `true` if successful.
     */
    function prepareNewStrategy(address newStrategy) external onlyAdmin returns (bool) {
        return _prepare(_STRATEGY_KEY, newStrategy, STRATEGY_DELAY);
    }

    /**
     * @notice Execute strategy update (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New strategy address.
     */
    function executeNewStrategy() external returns (address) {
        _executeDeadline(_STRATEGY_KEY);
        IStrategy strategy = getStrategy();
        if (address(strategy) != address(0)) {
            harvest();
            strategy.shutdown();
            strategy.withdrawAll();

            // there might still be some balance left if the strategy did not
            // manage to withdraw all funds (e.g. due to locking)
            uint256 remainingStrategyBalance = strategy.balance();
            if (remainingStrategyBalance > 0) {
                _strategiesWaitingForRemoval.set(address(strategy), remainingStrategyBalance);
                waitingForRemovalAllocated += remainingStrategyBalance;
            }
        }
        _deactivateStrategy();
        currentAllocated = 0;
        totalDebt = 0;
        address newStrategy = pendingAddresses[_STRATEGY_KEY];
        _setConfig(_STRATEGY_KEY, newStrategy);

        address newStrategist;

        if (newStrategy == address(0)) {
            newStrategist = address(0);
        } else {
            newStrategist = IStrategy(newStrategy).strategist();
            _activateStrategy();
        }

        if (newStrategist != strategist) {
            strategist = newStrategist;
            emit NewStrategist(newStrategist);
        }

        return newStrategy;
    }

    function resetNewStrategy() external onlyAdmin returns (bool) {
        return _resetAddressConfig(_STRATEGY_KEY);
    }

    /**
     * @notice Prepare update of performance fee (with time delay enforced).
     * @param newPerformanceFee New performance fee value.
     * @return `true` if successful.
     */
    function preparePerformanceFee(uint256 newPerformanceFee) external onlyAdmin returns (bool) {
        require(newPerformanceFee <= MAX_PERFORMANCE_FEE, Error.INVALID_AMOUNT);
        return _prepare(_PERFORMANCE_FEE_KEY, newPerformanceFee);
    }

    /**
     * @notice Execute update of performance fee (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New performance fee.
     */
    function executePerformanceFee() external returns (uint256) {
        return _executeUInt256(_PERFORMANCE_FEE_KEY);
    }

    function resetPerformanceFee() external onlyAdmin returns (bool) {
        return _resetUInt256Config(_PERFORMANCE_FEE_KEY);
    }

    /**
     * @notice Prepare update of strategist fee (with time delay enforced).
     * @param newStrategistFee New strategist fee value.
     * @return `true` if successful.
     */
    function prepareStrategistFee(uint256 newStrategistFee) external onlyAdmin returns (bool) {
        _checkFeesInvariant(getReserveFee(), newStrategistFee);
        return _prepare(_STRATEGIST_FEE_KEY, newStrategistFee);
    }

    /**
     * @notice Execute update of strategist fee (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New strategist fee.
     */
    function executeStrategistFee() external returns (uint256) {
        uint256 newStrategistFee = _executeUInt256(_STRATEGIST_FEE_KEY);
        _checkFeesInvariant(getReserveFee(), newStrategistFee);
        return newStrategistFee;
    }

    function resetStrategistFee() external onlyAdmin returns (bool) {
        return _resetUInt256Config(_STRATEGIST_FEE_KEY);
    }

    /**
     * @notice Prepare update of debt limit (with time delay enforced).
     * @param newDebtLimit New debt limit.
     * @return `true` if successful.
     */
    function prepareDebtLimit(uint256 newDebtLimit) external onlyAdmin returns (bool) {
        return _prepare(_DEBT_LIMIT_KEY, newDebtLimit);
    }

    /**
     * @notice Execute update of debt limit (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New debt limit.
     */
    function executeDebtLimit() external returns (uint256) {
        uint256 debtLimit = _executeUInt256(_DEBT_LIMIT_KEY);
        uint256 debtLimitAllocated = currentAllocated.scaledMul(debtLimit);
        if (totalDebt >= debtLimitAllocated) {
            _handleExcessDebt();
        }
        return debtLimit;
    }

    function resetDebtLimit() external onlyAdmin returns (bool) {
        return _resetUInt256Config(_DEBT_LIMIT_KEY);
    }

    /**
     * @notice Prepare update of target allocation (with time delay enforced).
     * @param newTargetAllocation New target allocation.
     * @return `true` if successful.
     */
    function prepareTargetAllocation(uint256 newTargetAllocation)
        external
        onlyAdmin
        returns (bool)
    {
        return _prepare(_TARGET_ALLOCATION_KEY, newTargetAllocation);
    }

    /**
     * @notice Execute update of target allocation (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New target allocation.
     */
    function executeTargetAllocation() external returns (uint256) {
        uint256 targetAllocation = _executeUInt256(_TARGET_ALLOCATION_KEY);
        _deposit();
        return targetAllocation;
    }

    function resetTargetAllocation() external onlyAdmin returns (bool) {
        return _resetUInt256Config(_TARGET_ALLOCATION_KEY);
    }

    /**
     * @notice Prepare update of reserve fee (with time delay enforced).
     * @param newReserveFee New reserve fee.
     * @return `true` if successful.
     */
    function prepareReserveFee(uint256 newReserveFee) external onlyAdmin returns (bool) {
        _checkFeesInvariant(newReserveFee, getStrategistFee());
        return _prepare(_RESERVE_FEE_KEY, newReserveFee);
    }

    /**
     * @notice Execute update of reserve fee (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New reserve fee.
     */
    function executeReserveFee() external returns (uint256) {
        uint256 newReserveFee = _executeUInt256(_RESERVE_FEE_KEY);
        _checkFeesInvariant(newReserveFee, getStrategistFee());
        return newReserveFee;
    }

    function resetReserveFee() external onlyAdmin returns (bool) {
        return _resetUInt256Config(_RESERVE_FEE_KEY);
    }

    /**
     * @notice Prepare update of deviation bound for strategy allocation (with time delay enforced).
     * @param newBound New deviation bound for target allocation.
     * @return `true` if successful.
     */
    function prepareBound(uint256 newBound) external onlyAdmin returns (bool) {
        require(newBound <= MAX_DEVIATION_BOUND, Error.INVALID_AMOUNT);
        return _prepare(_BOUND_KEY, newBound);
    }

    /**
     * @notice Execute update of deviation bound for strategy allocation (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New deviation bound.
     */
    function executeBound() external returns (uint256) {
        uint256 bound = _executeUInt256(_BOUND_KEY);
        _deposit();
        return bound;
    }

    function resetBound() external onlyAdmin returns (bool) {
        return _resetUInt256Config(_BOUND_KEY);
    }

    /**
     * @notice Withdraws an amount of underlying from the strategy to the vault.
     * @param amount Amount of underlying to withdraw.
     * @return True if successful withdrawal.
     */
    function withdrawFromStrategy(uint256 amount) external onlyAdmin returns (bool) {
        IStrategy strategy = getStrategy();
        if (address(strategy) == address(0)) return false;
        if (strategy.balance() < amount) return false;
        uint256 oldBalance = _availableUnderlying();
        strategy.withdraw(amount);
        uint256 newBalance = _availableUnderlying();
        currentAllocated -= newBalance - oldBalance;
        return true;
    }

    function withdrawFromStrategyWaitingForRemoval(address strategy) external returns (uint256) {
        (bool exists, uint256 allocated) = _strategiesWaitingForRemoval.tryGet(strategy);
        require(exists, Error.STRATEGY_DOES_NOT_EXIST);

        IStrategy istrategy = IStrategy(strategy);

        istrategy.harvest();
        uint256 withdrawn = istrategy.withdrawAll();

        uint256 _waitingForRemovalAllocated = waitingForRemovalAllocated;
        if (withdrawn >= _waitingForRemovalAllocated) {
            waitingForRemovalAllocated = 0;
        } else {
            waitingForRemovalAllocated = _waitingForRemovalAllocated - withdrawn;
        }

        if (withdrawn > allocated) {
            uint256 profit = withdrawn - allocated;
            uint256 strategistShare = _shareFees(profit.scaledMul(getPerformanceFee()));
            if (strategistShare > 0) {
                _payStrategist(strategistShare, istrategy.strategist());
            }
            allocated = 0;
            emit Harvest(profit, 0);
        } else {
            allocated -= withdrawn;
        }

        if (istrategy.balance() == 0) {
            _strategiesWaitingForRemoval.remove(strategy);
        } else {
            _strategiesWaitingForRemoval.set(strategy, allocated);
        }

        return withdrawn;
    }

    function getStrategiesWaitingForRemoval() external view returns (address[] memory) {
        return _strategiesWaitingForRemoval.keysArray();
    }

    /**
     * @notice Computes the total underlying of the vault: idle funds + allocated funds - debt
     * @return Total amount of underlying.
     */
    function getTotalUnderlying() external view override returns (uint256) {
        IStrategy strategy = getStrategy();
        uint256 availableUnderlying_ = _availableUnderlying();

        if (address(strategy) == address(0)) {
            return availableUnderlying_;
        }

        uint256 netUnderlying = availableUnderlying_ +
            currentAllocated +
            waitingForRemovalAllocated;
        if (totalDebt <= netUnderlying) return netUnderlying - totalDebt;
        return 0;
    }

    function getAllocatedToStrategyWaitingForRemoval(address strategy)
        external
        view
        returns (uint256)
    {
        return _strategiesWaitingForRemoval.get(strategy);
    }

    /**
     * @notice Withdraws all funds from strategy to vault.
     * @dev Harvests profits before withdrawing. Deactivates strategy after withdrawing.
     * @return `true` if successful.
     */
    function withdrawAllFromStrategy() public onlyAdmin returns (bool) {
        IStrategy strategy = getStrategy();
        if (address(strategy) == address(0)) return false;
        harvest();
        uint256 oldBalance = _availableUnderlying();
        strategy.withdrawAll();
        uint256 newBalance = _availableUnderlying();
        uint256 withdrawnAmount = newBalance - oldBalance;

        currentAllocated = _computeNewAllocated(currentAllocated, withdrawnAmount);
        _deactivateStrategy();
        return true;
    }

    /**
     * @notice Harvest profits from the vault's strategy.
     * @dev Harvesting adds profits to the vault's balance and deducts fees.
     *  No performance fees are charged on profit used to repay debt.
     * @return `true` if successful.
     */
    function harvest() public onlyAdmin returns (bool) {
        IStrategy strategy = getStrategy();
        if (address(strategy) == address(0)) {
            return false;
        }

        strategy.harvest();

        uint256 strategistShare = 0;

        uint256 allocatedUnderlying = strategy.balance();
        uint256 amountAllocated = currentAllocated;
        uint256 currentDebt = totalDebt;

        if (allocatedUnderlying > amountAllocated) {
            // we made profits
            uint256 profit = allocatedUnderlying - amountAllocated;

            if (profit > currentDebt) {
                if (currentDebt > 0) {
                    profit -= currentDebt;
                    currentDebt = 0;
                }
                (profit, strategistShare) = _shareProfit(profit);
            } else {
                currentDebt -= profit;
            }
            emit Harvest(profit, 0);
        } else if (allocatedUnderlying < amountAllocated) {
            // we made a loss
            uint256 loss = amountAllocated - allocatedUnderlying;
            currentDebt += loss;

            // check debt limit and withdraw funds if exceeded
            uint256 debtLimit = getDebtLimit();
            uint256 debtLimitAllocated = amountAllocated.scaledMul(debtLimit);
            if (currentDebt > debtLimitAllocated) {
                currentDebt = _handleExcessDebt(currentDebt);
            }
            emit Harvest(0, loss);
        } else {
            // nothing to declare
            return true;
        }

        totalDebt = currentDebt;
        currentAllocated = strategy.balance();

        if (strategistShare > 0) {
            _payStrategist(strategistShare);
        }

        return true;
    }

    /**
     * @notice Returns the percentage of the performance fee that goes to the strategist.
     */
    function getStrategistFee() public view returns (uint256) {
        return currentUInts256[_STRATEGIST_FEE_KEY];
    }

    function getStrategy() public view override returns (IStrategy) {
        return IStrategy(currentAddresses[_STRATEGY_KEY]);
    }

    /**
     * @notice Returns the percentage of the performance fee which is allocated to the vault reserve
     */
    function getReserveFee() public view returns (uint256) {
        return currentUInts256[_RESERVE_FEE_KEY];
    }

    /**
     * @notice Returns the fee charged on a strategy's generated profits.
     * @dev The strategist is paid in LP tokens, while the remainder of the profit stays in the vault.
     *      Default performance fee is set to 5% of harvested profits.
     */
    function getPerformanceFee() public view returns (uint256) {
        return currentUInts256[_PERFORMANCE_FEE_KEY];
    }

    /**
     * @notice Returns the allowed symmetric bound for target allocation (e.g. +- 5%)
     */
    function getBound() public view returns (uint256) {
        return currentUInts256[_BOUND_KEY];
    }

    /**
     * @notice The target percentage of total underlying funds to be allocated towards a strategy.
     * @dev this is to reduce gas costs. Withdrawals first come from idle funds and can therefore
     *      avoid unnecessary gas costs.
     */
    function getTargetAllocation() public view returns (uint256) {
        return currentUInts256[_TARGET_ALLOCATION_KEY];
    }

    /**
     * @notice The debt limit that the total debt of a strategy may not exceed.
     */
    function getDebtLimit() public view returns (uint256) {
        return currentUInts256[_DEBT_LIMIT_KEY];
    }

    function getUnderlying() public view virtual override returns (address);

    function _activateStrategy() internal returns (bool) {
        IStrategy strategy = getStrategy();
        if (address(strategy) == address(0)) return false;

        strategyActive = true;
        emit StrategyActivated(address(strategy));
        _deposit();
        return true;
    }

    function _handleExcessDebt(uint256 currentDebt) internal returns (uint256) {
        uint256 underlyingReserves = _reserveBalance();
        if (currentDebt > underlyingReserves) {
            _emergencyStop(underlyingReserves);
        } else {
            reserve.withdraw(getUnderlying(), currentDebt);
            currentDebt = 0;
            _deposit();
        }
        return currentDebt;
    }

    function _handleExcessDebt() internal {
        uint256 currentDebt = totalDebt;
        uint256 newDebt = _handleExcessDebt(totalDebt);
        if (currentDebt != newDebt) {
            totalDebt = newDebt;
        }
    }

    /**
     * @notice Invest the underlying money in the vault after a deposit from the pool is made.
     * @dev After each deposit, the vault checks whether it needs to rebalance underlying funds allocated to strategy.
     * If no strategy is set then all deposited funds will be idle.
     */
    function _deposit() internal {
        if (!strategyActive) return;

        uint256 availableUnderlying_ = _availableUnderlying();
        uint256 allocatedUnderlying = getStrategy().balance();
        uint256 totalUnderlying = availableUnderlying_ +
            allocatedUnderlying +
            waitingForRemovalAllocated;

        if (totalUnderlying == 0) return;
        _rebalance(totalUnderlying, allocatedUnderlying);
    }

    function _shareProfit(uint256 profit) internal returns (uint256, uint256) {
        uint256 totalFeeAmount = profit.scaledMul(getPerformanceFee());
        getStrategy().withdraw(totalFeeAmount);
        uint256 strategistShare = _shareFees(totalFeeAmount);

        return ((profit - totalFeeAmount), strategistShare);
    }

    function _shareFees(uint256 totalFeeAmount) internal returns (uint256) {
        uint256 strategistShare = totalFeeAmount.scaledMul(getStrategistFee());

        uint256 reserveShare = totalFeeAmount.scaledMul(getReserveFee());
        uint256 treasuryShare = totalFeeAmount - strategistShare - reserveShare;

        _depositToReserve(reserveShare);
        if (treasuryShare > 0) {
            _depositToTreasury(treasuryShare);
        }
        return strategistShare;
    }

    function _emergencyStop(uint256 underlyingReserves) internal {
        // debt limit exceeded: withdraw funds from strategy
        uint256 withdrawn = getStrategy().withdrawAll();

        uint256 actualDebt = _computeNewAllocated(currentAllocated, withdrawn);

        // check if debt can be covered with reserve funds
        if (underlyingReserves >= actualDebt) {
            reserve.withdraw(getUnderlying(), actualDebt);
        } else if (underlyingReserves > 0) {
            // debt can not be covered with reserves
            reserve.withdraw(getUnderlying(), underlyingReserves);
        }
        // too much money lost, stop the strategy
        _deactivateStrategy();
    }

    /**
     * @notice Deactivates a strategy. All positions of the strategy are exited.
     * @return `true` if strategy has been deactivated
     */
    function _deactivateStrategy() internal returns (bool) {
        if (!strategyActive) return false;

        strategyActive = false;
        emit StrategyDeactivated(address(getStrategy()));
        return true;
    }

    function _payStrategist(uint256 amount) internal {
        _payStrategist(amount, strategist);
    }

    function _payStrategist(uint256 amount, address strategist) internal virtual;

    function _transfer(address to, uint256 amount) internal virtual;

    function _depositToReserve(uint256 amount) internal virtual;

    function _depositToTreasury(uint256 amount) internal virtual;

    function _availableUnderlying() internal view virtual returns (uint256);

    function _reserveBalance() internal view virtual returns (uint256);

    function _computeNewAllocated(uint256 allocated, uint256 withdrawn)
        internal
        pure
        returns (uint256)
    {
        if (allocated > withdrawn) {
            return allocated - withdrawn;
        }
        return 0;
    }

    function _checkFeesInvariant(uint256 reserveFee, uint256 strategistFee) internal pure {
        require(
            reserveFee + strategistFee <= DECIMAL_SCALE,
            "sum of strategist fee and reserve fee should be below 1"
        );
    }

    function _rebalance(uint256 totalUnderlying, uint256 allocatedUnderlying)
        private
        returns (bool)
    {
        if (!strategyActive) return false;
        // check if strategy should receive any funds
        uint256 targetAllocation = getTargetAllocation();
        if (targetAllocation == 0) return false;

        IStrategy strategy = getStrategy();
        uint256 bound = getBound();

        uint256 target = totalUnderlying.scaledMul(targetAllocation);
        uint256 upperBound = targetAllocation + bound;
        upperBound = upperBound > DECIMAL_SCALE ? DECIMAL_SCALE : upperBound;
        uint256 lowerBound = bound > targetAllocation ? 0 : targetAllocation - bound;
        if (allocatedUnderlying > totalUnderlying.scaledMul(upperBound)) {
            // withdraw funds from strategy
            uint256 withdrawAmount = allocatedUnderlying - target;
            strategy.withdraw(withdrawAmount);

            currentAllocated = _computeNewAllocated(currentAllocated, withdrawAmount);
        } else if (allocatedUnderlying < totalUnderlying.scaledMul(lowerBound)) {
            // allocate more funds to strategy
            uint256 depositAmount = target - allocatedUnderlying;
            _transfer(address(strategy), depositAmount);
            currentAllocated += depositAmount;
            strategy.deposit();
        }
        return true;
    }
}
