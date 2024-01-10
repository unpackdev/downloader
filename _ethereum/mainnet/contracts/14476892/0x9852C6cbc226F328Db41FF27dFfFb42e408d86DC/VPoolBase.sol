// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Errors.sol";
import "./PoolShareToken.sol";
import "./IStrategy.sol";

abstract contract VPoolBase is PoolShareToken {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant BLOCKS_PER_YEAR = 2336000;

    event UpdatedUniversalFee(uint256 oldUniversalFee, uint256 newUniversalFee);
    event UpdatedPoolRewards(address indexed previousPoolRewards, address indexed newPoolRewards);
    event UpdatedWithdrawFee(uint256 previousWithdrawFee, uint256 newWithdrawFee);

    constructor(
        string memory _name,
        string memory _symbol,
        address _token // solhint-disable-next-line no-empty-blocks
    ) PoolShareToken(_name, _symbol, _token) {}

    /// @dev Equivalent to constructor for proxy. It can be called only once per proxy.
    function _initializeBase(
        string memory _name,
        string memory _symbol,
        address _token,
        address _poolAccountant
    ) internal initializer {
        require(_poolAccountant != address(0), Errors.INPUT_ADDRESS_IS_ZERO);
        _initializePool(_name, _symbol, _token);
        _initializeGoverned();
        require(_keepers.add(_msgSender()), Errors.ADD_IN_LIST_FAILED);
        require(_maintainers.add(_msgSender()), Errors.ADD_IN_LIST_FAILED);
        poolAccountant = _poolAccountant;
    }

    modifier onlyKeeper() {
        require(governor == _msgSender() || _keepers.contains(_msgSender()), "not-a-keeper");
        _;
    }

    modifier onlyMaintainer() {
        require(governor == _msgSender() || _maintainers.contains(_msgSender()), "not-a-maintainer");
        _;
    }

    ////////////////////////////// Only Governor //////////////////////////////

    /**
     * @notice Migrate existing strategy to new strategy.
     * @dev Migrating strategy aka old and new strategy should be of same type.
     * @param _old Address of strategy being migrated
     * @param _new Address of new strategy
     */
    function migrateStrategy(address _old, address _new) external onlyGovernor {
        require(
            IStrategy(_new).pool() == address(this) && IStrategy(_old).pool() == address(this),
            Errors.INVALID_STRATEGY
        );
        IPoolAccountant(poolAccountant).migrateStrategy(_old, _new);
        IStrategy(_old).migrate(_new);
    }

    /**
     * @notice Update universal fee for this pool
     * @dev Format: 1500 = 15% fee, 100 = 1%
     * @param _newUniversalFee new universal fee
     */
    function updateUniversalFee(uint256 _newUniversalFee) external onlyGovernor {
        require(_newUniversalFee <= MAX_BPS, Errors.FEE_LIMIT_REACHED);
        emit UpdatedUniversalFee(universalFee, _newUniversalFee);
        universalFee = _newUniversalFee;
    }

    /**
     * @notice Update pool rewards address for this pool
     * @param _newPoolRewards new pool rewards address
     */
    function updatePoolRewards(address _newPoolRewards) external onlyGovernor {
        require(_newPoolRewards != address(0), Errors.INPUT_ADDRESS_IS_ZERO);
        emit UpdatedPoolRewards(poolRewards, _newPoolRewards);
        poolRewards = _newPoolRewards;
    }

    ///////////////////////////// Only Keeper ///////////////////////////////
    function pause() external onlyKeeper {
        _pause();
    }

    function unpause() external onlyKeeper {
        _unpause();
    }

    function shutdown() external onlyKeeper {
        _shutdown();
    }

    function open() external onlyKeeper {
        _open();
    }

    /// @notice Return list of keepers
    function keepers() external view returns (address[] memory) {
        return _keepers.values();
    }

    function isKeeper(address _address) external view returns (bool) {
        return _keepers.contains(_address);
    }

    /**
     * @notice Add given address in keepers list.
     * @param _keeperAddress keeper address to add.
     */
    function addKeeper(address _keeperAddress) external onlyKeeper {
        require(_keepers.add(_keeperAddress), Errors.ADD_IN_LIST_FAILED);
    }

    /**
     * @notice Remove given address from keepers list.
     * @param _keeperAddress keeper address to remove.
     */
    function removeKeeper(address _keeperAddress) external onlyKeeper {
        require(_keepers.remove(_keeperAddress), Errors.REMOVE_FROM_LIST_FAILED);
    }

    /// @notice Return list of maintainers
    function maintainers() external view returns (address[] memory) {
        return _maintainers.values();
    }

    function isMaintainer(address _address) external view returns (bool) {
        return _maintainers.contains(_address);
    }

    /**
     * @notice Add given address in maintainers list.
     * @param _maintainerAddress maintainer address to add.
     */
    function addMaintainer(address _maintainerAddress) external onlyKeeper {
        require(_maintainers.add(_maintainerAddress), Errors.ADD_IN_LIST_FAILED);
    }

    /**
     * @notice Remove given address from maintainers list.
     * @param _maintainerAddress maintainer address to remove.
     */
    function removeMaintainer(address _maintainerAddress) external onlyKeeper {
        require(_maintainers.remove(_maintainerAddress), Errors.REMOVE_FROM_LIST_FAILED);
    }

    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Calculate universal fee for calling strategy. This is only strategy function.
     * @dev Earn strategies will call this during rebalance.
     */
    function calculateUniversalFee(uint256 _profit) external view returns (uint256 _fee) {
        return _calculateUniversalFee(_msgSender(), _profit);
    }

    /**
     * @notice Strategy call this in regular interval. Only strategy function.
     * @param _profit yield generated by strategy. Strategy get performance fee on this amount
     * @param _loss  Reduce debt ,also reduce debtRatio, increase loss in record.
     * @param _payback strategy willing to payback outstanding above debtLimit. no performance fee on this amount.
     *  when governance has reduced debtRatio of strategy, strategy will report profit and payback amount separately.
     */
    function reportEarning(
        uint256 _profit,
        uint256 _loss,
        uint256 _payback
    ) external virtual {
        address _strategy = _msgSender();
        // Calculate universal fee
        if (_profit > 0) {
            uint256 _fee = _calculateUniversalFee(_strategy, _profit);
            // Mint shares equal to universal fee
            if (_fee > 0) {
                _mint(IStrategy(_strategy).feeCollector(), _calculateShares(_fee));
            }
        }

        // Report earning in pool accountant
        (uint256 _actualPayback, uint256 _creditLine) =
            IPoolAccountant(poolAccountant).reportEarning(_strategy, _profit, _loss, _payback);
        uint256 _totalPayback = _profit + _actualPayback;
        // After payback, if strategy has credit line available then send more fund to strategy
        // If payback is more than available credit line then get fund from strategy
        if (_totalPayback < _creditLine) {
            token.safeTransfer(_strategy, _creditLine - _totalPayback);
        } else if (_totalPayback > _creditLine) {
            token.safeTransferFrom(_strategy, address(this), _totalPayback - _creditLine);
        }
    }

    /**
     * @notice Report loss outside of rebalance activity.
     * @dev Some strategies pay deposit fee thus realizing loss at deposit.
     * For example: Curve's 3pool has some slippage due to deposit of one asset in 3pool.
     * Strategy may want report this loss instead of waiting for next rebalance.
     * @param _loss Loss that strategy want to report
     */
    function reportLoss(uint256 _loss) external {
        if (_loss > 0) {
            IPoolAccountant(poolAccountant).reportLoss(_msgSender(), _loss);
        }
    }

    /**
     * @dev Transfer given ERC20 token to governor
     * @param _fromToken Token address to sweep
     */
    function sweepERC20(address _fromToken) external virtual onlyKeeper {
        require(_fromToken != address(token), Errors.NOT_ALLOWED_TO_SWEEP);
        IERC20(_fromToken).safeTransfer(governor, IERC20(_fromToken).balanceOf(address(this)));
    }

    /**
     * @notice Get available credit limit of strategy. This is the amount strategy can borrow from pool
     * @dev Available credit limit is calculated based on current debt of pool and strategy, current debt limit of pool and strategy.
     * credit available = min(pool's debt limit, strategy's debt limit, max debt per rebalance)
     * when some strategy do not pay back outstanding debt, this impact credit line of other strategy if totalDebt of pool >= debtLimit of pool
     * @param _strategy Strategy address
     */
    function availableCreditLimit(address _strategy) external view returns (uint256) {
        return IPoolAccountant(poolAccountant).availableCreditLimit(_strategy);
    }

    /**
     * @notice Debt above current debt limit
     * @param _strategy Address of strategy
     */
    function excessDebt(address _strategy) external view returns (uint256) {
        return IPoolAccountant(poolAccountant).excessDebt(_strategy);
    }

    function getStrategies() public view returns (address[] memory) {
        return IPoolAccountant(poolAccountant).getStrategies();
    }

    function getWithdrawQueue() public view returns (address[] memory) {
        return IPoolAccountant(poolAccountant).getWithdrawQueue();
    }

    function strategy(address _strategy)
        public
        view
        returns (
            bool _active,
            uint256 interestFeeObsolete,
            uint256 _debtRate,
            uint256 _lastRebalance,
            uint256 _totalDebt,
            uint256 _totalLoss,
            uint256 _totalProfit,
            uint256 _debtRatio,
            uint256 _externalDepositFee
        )
    {
        return IPoolAccountant(poolAccountant).strategy(_strategy);
    }

    /// @notice Get total debt of pool
    function totalDebt() external view returns (uint256) {
        return IPoolAccountant(poolAccountant).totalDebt();
    }

    /**
     * @notice Get total debt of given strategy
     * @param _strategy Strategy address
     */
    function totalDebtOf(address _strategy) public view returns (uint256) {
        return IPoolAccountant(poolAccountant).totalDebtOf(_strategy);
    }

    /// @notice Get total debt ratio. Total debt ratio helps us keep buffer in pool
    function totalDebtRatio() external view returns (uint256) {
        return IPoolAccountant(poolAccountant).totalDebtRatio();
    }

    /// @dev Returns total value of vesper pool, in terms of collateral token
    function totalValue() public view override returns (uint256) {
        return IPoolAccountant(poolAccountant).totalDebt() + tokensHere();
    }

    function _withdrawCollateral(uint256 _amount) internal virtual {
        // Withdraw amount from queue
        uint256 _debt;
        uint256 _balanceAfter;
        uint256 _balanceBefore;
        uint256 _amountWithdrawn;
        uint256 _totalAmountWithdrawn;
        address[] memory _withdrawQueue = getWithdrawQueue();
        uint256 _len = _withdrawQueue.length;
        for (uint256 i; i < _len; i++) {
            uint256 _amountNeeded = _amount - _totalAmountWithdrawn;
            address _strategy = _withdrawQueue[i];
            _debt = totalDebtOf(_strategy);
            if (_debt == 0) {
                continue;
            }
            if (_amountNeeded > _debt) {
                // Should not withdraw more than current debt of strategy.
                _amountNeeded = _debt;
            }
            _balanceBefore = tokensHere();
            //solhint-disable no-empty-blocks
            try IStrategy(_strategy).withdraw(_amountNeeded) {} catch {
                continue;
            }
            _balanceAfter = tokensHere();
            _amountWithdrawn = _balanceAfter - _balanceBefore;
            // Adjusting totalDebt. Assuming that during next reportEarning(), strategy will report loss if amountWithdrawn < _amountNeeded
            IPoolAccountant(poolAccountant).decreaseDebt(_strategy, _amountWithdrawn);
            _totalAmountWithdrawn += _amountWithdrawn;
            if (_totalAmountWithdrawn >= _amount) {
                // withdraw done
                break;
            }
        }
    }

    /**
     * @dev Before burning hook.
     * withdraw amount from strategies
     */
    function _beforeBurning(uint256 _share) internal override returns (uint256 _actualWithdrawn, bool _isPartial) {
        uint256 _amount = (_share * pricePerShare()) / 1e18;
        uint256 _tokensHere = tokensHere();
        _actualWithdrawn = _amount;
        // Check for partial withdraw scenario
        // If we do not have enough tokens then withdraw whats needed from strategy
        if (_amount > _tokensHere) {
            // Strategy may withdraw partial
            _withdrawCollateral(_amount - _tokensHere);
            _tokensHere = tokensHere();
            if (_amount > _tokensHere) {
                _actualWithdrawn = _tokensHere;
                _isPartial = true;
            }
        }
        require(_actualWithdrawn > 0, Errors.INVALID_COLLATERAL_AMOUNT);
    }

    /**
     * @dev Calculate universal fee based on strategy's TVL, profit earned and duration between rebalance and now.
     */
    function _calculateUniversalFee(address _strategy, uint256 _profit) private view returns (uint256 _fee) {
        // Calculate universal fee
        (, , , uint256 _lastRebalanceAt, uint256 _totalDebt, , , , ) =
            IPoolAccountant(poolAccountant).strategy(_strategy);
        _fee = (universalFee * (block.number - _lastRebalanceAt) * _totalDebt) / (MAX_BPS * BLOCKS_PER_YEAR);
        if (_fee > (_profit / 2)) {
            _fee = _profit / 2;
        }
    }
}
