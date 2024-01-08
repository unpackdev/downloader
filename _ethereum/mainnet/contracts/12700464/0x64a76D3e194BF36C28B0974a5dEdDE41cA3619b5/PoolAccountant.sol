// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./Initializable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./Errors.sol";
import "./IVesperPool.sol";

contract PoolAccountantStorageV1 {
    address public pool; // Address of Vesper pool
    uint256 public totalDebtRatio; // Total debt ratio. This will keep some buffer amount in pool
    uint256 public totalDebt; // Total debt. Sum of debt of all strategies.
    address[] public strategies; // Array of strategies
    address[] public withdrawQueue; // Array of strategy in the order in which funds should be withdrawn.

    struct StrategyConfig {
        bool active;
        uint256 interestFee; // Strategy fee
        uint256 debtRate; // Strategy can not borrow large amount in short durations. Can set big limit for trusted strategy
        uint256 lastRebalance; // Timestamp of last rebalance
        uint256 totalDebt; // Total outstanding debt strategy has
        uint256 totalLoss; // Total loss that strategy has realized
        uint256 totalProfit; // Total gain that strategy has realized
        uint256 debtRatio; // % of asset allocation
    }

    mapping(address => StrategyConfig) public strategy; // Strategy address to its configuration
}

/// @title Accountant for Vesper pools which keep records of strategies.
contract PoolAccountant is Initializable, PoolAccountantStorageV1, Context {
    using SafeERC20 for IERC20;

    string public constant VERSION = "3.0.3";
    uint256 public constant MAX_BPS = 10_000;

    event EarningReported(
        address indexed strategy,
        uint256 profit,
        uint256 loss,
        uint256 payback,
        uint256 strategyDebt,
        uint256 poolDebt,
        uint256 creditLine
    );
    event StrategyAdded(address indexed strategy, uint256 interestFee, uint256 debtRatio, uint256 debtRate);
    event StrategyMigrated(
        address indexed oldStrategy,
        address indexed newStrategy,
        uint256 interestFee,
        uint256 debtRatio,
        uint256 debtRate
    );
    event UpdatedInterestFee(address indexed strategy, uint256 interestFee);
    event UpdatedStrategyDebtParams(address indexed strategy, uint256 debtRatio, uint256 debtRate);

    /**
     * @dev This init function meant to be called after proxy deployment.
     * @dev DO NOT CALL it with proxy deploy
     * @param _pool Address of Vesper pool proxy
     */
    function init(address _pool) public initializer {
        pool = _pool;
    }

    modifier onlyGovernor() {
        require(IVesperPool(pool).governor() == _msgSender(), "not-the-governor");
        _;
    }

    modifier onlyKeeper() {
        require(IVesperPool(pool).keepers().contains(_msgSender()), "not-a-keeper");
        _;
    }

    modifier onlyMaintainer() {
        require(IVesperPool(pool).maintainers().contains(_msgSender()), "not-a-maintainer");
        _;
    }

    modifier onlyPool() {
        require(pool == _msgSender(), "not-a-pool");
        _;
    }

    ////////////////////////////// Only Governor //////////////////////////////

    /**
     * @notice Add strategy. Once strategy is added it can call rebalance and
     * borrow fund from pool and invest that fund in provider/lender.
     * @param _strategy Strategy address
     * @param _interestFee Fee on earnings from this strategy
     * @param _debtRatio Pool fund allocation to this strategy
     * @param _debtRate Debt rate per block
     */
    function addStrategy(
        address _strategy,
        uint256 _interestFee,
        uint256 _debtRatio,
        uint256 _debtRate
    ) public onlyGovernor {
        require(_strategy != address(0), Errors.INPUT_ADDRESS_IS_ZERO);
        require(!strategy[_strategy].active, Errors.STRATEGY_IS_ACTIVE);
        totalDebtRatio = totalDebtRatio + _debtRatio;
        require(totalDebtRatio <= MAX_BPS, Errors.DEBT_RATIO_LIMIT_REACHED);
        require(_interestFee <= MAX_BPS, Errors.FEE_LIMIT_REACHED);
        StrategyConfig memory newStrategy =
            StrategyConfig({
                active: true,
                interestFee: _interestFee,
                debtRatio: _debtRatio,
                totalDebt: 0,
                totalProfit: 0,
                totalLoss: 0,
                debtRate: _debtRate,
                lastRebalance: block.number
            });
        strategy[_strategy] = newStrategy;
        strategies.push(_strategy);
        withdrawQueue.push(_strategy);
        emit StrategyAdded(_strategy, _interestFee, _debtRatio, _debtRate);
    }

    /**
     * @dev Revoke and remove strategy from array. Update withdraw queue.
     * Withdraw queue order should not change after remove.
     * Strategy can be removed only after it has paid all debt.
     * Use migrate strategy if debt is not paid and want to upgrade strategy.
     */
    function removeStrategy(uint256 _index) external onlyGovernor {
        address _strategy = strategies[_index];
        require(strategy[_strategy].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        require(strategy[_strategy].totalDebt == 0, Errors.TOTAL_DEBT_IS_NOT_ZERO);
        delete strategy[_strategy];
        strategies[_index] = strategies[strategies.length - 1];
        strategies.pop();
        address[] memory _withdrawQueue = new address[](strategies.length);
        uint256 j;
        // After above update, withdrawQueue.length > strategies.length
        for (uint256 i = 0; i < withdrawQueue.length; i++) {
            if (withdrawQueue[i] != _strategy) {
                _withdrawQueue[j] = withdrawQueue[i];
                j++;
            }
        }
        withdrawQueue = _withdrawQueue;
    }

    /**
     * @notice Update interest fee of strategy
     * @param _strategy Strategy address for which interest fee is being updated
     * @param _interestFee New interest fee
     */
    function updateInterestFee(address _strategy, uint256 _interestFee) external onlyGovernor {
        require(strategy[_strategy].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        require(_interestFee <= MAX_BPS, Errors.FEE_LIMIT_REACHED);
        strategy[_strategy].interestFee = _interestFee;
        emit UpdatedInterestFee(_strategy, _interestFee);
    }

    ///////////////////////////// Only Keeper /////////////////////////////
    /**
     * @notice Update debtRate per block.
     * @param _strategy Strategy address for which debt rate is being updated
     * @param _debtRate New debt rate
     */
    function updateDebtRate(address _strategy, uint256 _debtRate) external onlyKeeper {
        require(strategy[_strategy].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        strategy[_strategy].debtRate = _debtRate;
        emit UpdatedStrategyDebtParams(_strategy, strategy[_strategy].debtRatio, _debtRate);
    }

    /**
     * @dev Transfer given ERC20 token to pool
     * @param _fromToken Token address to sweep
     */
    function sweepERC20(address _fromToken) external virtual onlyKeeper {
        IERC20(_fromToken).safeTransfer(pool, IERC20(_fromToken).balanceOf(address(this)));
    }

    ///////////////////////////// Only Maintainer /////////////////////////////
    /**
     * @notice Update debt ratio.
     * @dev A strategy is retired when debtRatio is 0
     * @param _strategy Strategy address for which debt ratio is being updated
     * @param _debtRatio New debt ratio
     */
    function updateDebtRatio(address _strategy, uint256 _debtRatio) external onlyMaintainer {
        require(strategy[_strategy].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        totalDebtRatio = totalDebtRatio - strategy[_strategy].debtRatio + _debtRatio;
        require(totalDebtRatio <= MAX_BPS, Errors.DEBT_RATIO_LIMIT_REACHED);
        strategy[_strategy].debtRatio = _debtRatio;
        emit UpdatedStrategyDebtParams(_strategy, _debtRatio, strategy[_strategy].debtRate);
    }

    /**
     * @notice Update withdraw queue. Withdraw queue is list of strategy in the order in which
     * funds should be withdrawn.
     * @dev Pool always keep some buffer amount to satisfy withdrawal request, any withdrawal
     * request higher than buffer will withdraw from withdraw queue. So withdrawQueue[0] will
     * be the first strategy where withdrawal request will be send.
     * @param _withdrawQueue Ordered list of strategy.
     */
    function updateWithdrawQueue(address[] memory _withdrawQueue) external onlyMaintainer {
        uint256 _length = _withdrawQueue.length;
        require(_length == withdrawQueue.length && _length == strategies.length, Errors.INPUT_LENGTH_MISMATCH);
        for (uint256 i = 0; i < _length; i++) {
            require(strategy[_withdrawQueue[i]].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        }
        withdrawQueue = _withdrawQueue;
    }

    //////////////////////////////// Only Pool ////////////////////////////////

    /**
     * @notice Migrate existing strategy to new strategy.
     * @dev Migrating strategy aka old and new strategy should be of same type.
     * @dev New strategy will replace old strategy in strategy mapping,
     * strategies array, withdraw queue.
     * @param _old Address of strategy being migrated
     * @param _new Address of new strategy
     */
    function migrateStrategy(address _old, address _new) external onlyPool {
        require(strategy[_old].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        require(!strategy[_new].active, Errors.STRATEGY_IS_ACTIVE);
        StrategyConfig memory _newStrategy =
            StrategyConfig({
                active: true,
                interestFee: strategy[_old].interestFee,
                debtRatio: strategy[_old].debtRatio,
                totalDebt: strategy[_old].totalDebt,
                totalProfit: 0,
                totalLoss: 0,
                debtRate: strategy[_old].debtRate,
                lastRebalance: strategy[_old].lastRebalance
            });
        delete strategy[_old];
        strategy[_new] = _newStrategy;

        // Strategies and withdrawQueue has same length but we still want
        // to iterate over them in different loop.
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i] == _old) {
                strategies[i] = _new;
                break;
            }
        }
        for (uint256 i = 0; i < withdrawQueue.length; i++) {
            if (withdrawQueue[i] == _old) {
                withdrawQueue[i] = _new;
                break;
            }
        }
        emit StrategyMigrated(
            _old,
            _new,
            strategy[_new].interestFee,
            strategy[_new].debtRatio,
            strategy[_new].debtRate
        );
    }

    /**
     * @dev Strategy call this in regular interval.
     * @param _profit yield generated by strategy. Strategy get performance fee on this amount
     * @param _loss  Reduce debt ,also reduce debtRatio, increase loss in record.
     * @param _payback strategy willing to payback outstanding above debtLimit. no performance fee on this amount.
     *  when governance has reduced debtRatio of strategy, strategy will report profit and payback amount separately.
     */
    function reportEarning(
        address _strategy,
        uint256 _profit,
        uint256 _loss,
        uint256 _payback
    )
        external
        onlyPool
        returns (
            uint256 _actualPayback,
            uint256 _creditLine,
            uint256 _fee
        )
    {
        require(strategy[_strategy].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        require(IVesperPool(pool).token().balanceOf(_strategy) >= (_profit + _payback), Errors.INSUFFICIENT_BALANCE);
        if (_loss != 0) {
            _reportLoss(_strategy, _loss);
        }

        uint256 _overLimitDebt = _excessDebt(_strategy);
        _actualPayback = _min(_overLimitDebt, _payback);
        if (_actualPayback != 0) {
            strategy[_strategy].totalDebt -= _actualPayback;
            totalDebt -= _actualPayback;
        }
        _creditLine = _availableCreditLimit(_strategy);
        if (_creditLine != 0) {
            strategy[_strategy].totalDebt += _creditLine;
            totalDebt += _creditLine;
        }
        if (_profit != 0) {
            strategy[_strategy].totalProfit += _profit;
            _fee = (_profit * strategy[_strategy].interestFee) / MAX_BPS;
        }
        emit EarningReported(
            _strategy,
            _profit,
            _loss,
            _actualPayback,
            strategy[_strategy].totalDebt,
            totalDebt,
            _creditLine
        );
        return (_actualPayback, _creditLine, _fee);
    }

    /**
     * @notice Update strategy loss.
     * @param _strategy Strategy which incur loss
     * @param _loss Loss of strategy
     */
    function reportLoss(address _strategy, uint256 _loss) external onlyPool {
        require(strategy[_strategy].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        _reportLoss(_strategy, _loss);
    }

    /**
     * @notice Decrease debt of strategy, also decrease totalDebt
     * @dev In case of withdraw from strategy, pool will decrease debt by amount withdrawn
     * @param _strategy Strategy Address
     * @param _decreaseBy Amount by which strategy debt will be decreased
     */
    function decreaseDebt(address _strategy, uint256 _decreaseBy) external onlyPool {
        strategy[_strategy].totalDebt -= _decreaseBy;
        totalDebt -= _decreaseBy;
    }

    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Get available credit limit of strategy. This is the amount strategy can borrow from pool
     * @dev Available credit limit is calculated based on current debt of pool and strategy, current debt limit of pool and strategy.
     * credit available = min(pool's debt limit, strategy's debt limit, max debt per rebalance)
     * when some strategy do not pay back outstanding debt, this impact credit line of other strategy if totalDebt of pool >= debtLimit of pool
     * @param _strategy Strategy address
     */
    function availableCreditLimit(address _strategy) external view returns (uint256) {
        return _availableCreditLimit(_strategy);
    }

    /**
     * @notice Debt above current debt limit
     * @param _strategy Address of strategy
     */
    function excessDebt(address _strategy) external view returns (uint256) {
        return _excessDebt(_strategy);
    }

    /// @notice Return strategies array
    function getStrategies() external view returns (address[] memory) {
        return strategies;
    }

    /// @notice Return withdrawQueue
    function getWithdrawQueue() external view returns (address[] memory) {
        return withdrawQueue;
    }

    /**
     * @notice Get total debt of given strategy
     * @param _strategy Strategy address
     */
    function totalDebtOf(address _strategy) external view returns (uint256) {
        return strategy[_strategy].totalDebt;
    }

    /**
     * @dev When strategy report loss, its debtRatio decreases to get fund back quickly.
     * Reduction is debt ratio is reduction in credit limit
     */
    function _reportLoss(address _strategy, uint256 _loss) internal {
        uint256 _currentDebt = strategy[_strategy].totalDebt;
        require(_currentDebt >= _loss, Errors.LOSS_TOO_HIGH);
        strategy[_strategy].totalLoss += _loss;
        strategy[_strategy].totalDebt -= _loss;
        totalDebt -= _loss;
        uint256 _deltaDebtRatio =
            _min((_loss * MAX_BPS) / IVesperPool(pool).totalValue(), strategy[_strategy].debtRatio);
        strategy[_strategy].debtRatio -= _deltaDebtRatio;
        totalDebtRatio -= _deltaDebtRatio;
    }

    function _availableCreditLimit(address _strategy) internal view returns (uint256) {
        if (IVesperPool(pool).stopEverything()) {
            return 0;
        }
        uint256 _totalValue = IVesperPool(pool).totalValue();
        uint256 _maxDebt = (strategy[_strategy].debtRatio * _totalValue) / MAX_BPS;
        uint256 _currentDebt = strategy[_strategy].totalDebt;
        if (_currentDebt >= _maxDebt) {
            return 0;
        }
        uint256 _poolDebtLimit = (totalDebtRatio * _totalValue) / MAX_BPS;
        if (totalDebt >= _poolDebtLimit) {
            return 0;
        }
        uint256 _available = _maxDebt - _currentDebt;
        _available = _min(_min(IVesperPool(pool).tokensHere(), _available), _poolDebtLimit - totalDebt);
        _available = _min(
            (block.number - strategy[_strategy].lastRebalance) * strategy[_strategy].debtRate,
            _available
        );
        return _available;
    }

    function _excessDebt(address _strategy) internal view returns (uint256) {
        uint256 _currentDebt = strategy[_strategy].totalDebt;
        if (IVesperPool(pool).stopEverything()) {
            return _currentDebt;
        }
        uint256 _maxDebt = (strategy[_strategy].debtRatio * IVesperPool(pool).totalValue()) / MAX_BPS;
        return _currentDebt > _maxDebt ? (_currentDebt - _maxDebt) : 0;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
