// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./PoolShareToken.sol";
import "./IStrategy.sol";

contract VTokenBase is PoolShareToken {
    using SafeERC20 for IERC20;

    struct StrategyConfig {
        bool active;
        uint256 interestFee; // Strategy fee
        uint256 debtRate; //strategy can not borrow large amount in short durations. Can set big limit for trusted strategy
        uint256 lastRebalance;
        uint256 totalDebt; // Total outstanding debt strategy has
        uint256 totalLoss; // Total loss that strategy has realized
        uint256 totalProfit; // Total gain that strategy has realized
        uint256 debtRatio; // % of asset allocation
    }

    mapping(address => StrategyConfig) public strategy;
    uint256 public totalDebtRatio; // this will keep some buffer amount in pool
    uint256 public totalDebt;
    address[] public strategies;
    address[] public withdrawQueue;

    IAddressList public keepers;
    IAddressList public maintainers;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
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
    event EarningReported(
        address indexed strategy,
        uint256 profit,
        uint256 loss,
        uint256 payback,
        uint256 strategyDebt,
        uint256 poolDebt,
        uint256 creditLine
    );

    constructor(
        string memory name,
        string memory symbol,
        address _token // solhint-disable-next-line no-empty-blocks
    ) PoolShareToken(name, symbol, _token) {}

    modifier onlyKeeper() {
        require(keepers.contains(_msgSender()), "caller-is-not-a-keeper");
        _;
    }

    modifier onlyMaintainer() {
        require(maintainers.contains(_msgSender()), "caller-is-not-maintainer");
        _;
    }

    modifier onlyStrategy() {
        require(strategy[_msgSender()].active, "caller-is-not-active-strategy");
        _;
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

    ///////////////////////////////////////////////////////////////////////////

    ////////////////////////////// Only Governor //////////////////////////////

    /**
     * @notice Create keeper and maintainer list
     * @dev Create lists and add governor into the list.
     * NOTE: Any function with onlyKeeper and onlyMaintainer modifier will not work until this function is called.
     * NOTE: Due to gas constraint this function cannot be called in constructor.
     */
    function init() external onlyGovernor {
        require(address(keepers) == address(0), "list-already-created");
        IAddressListFactory _factory = IAddressListFactory(0xded8217De022706A191eE7Ee0Dc9df1185Fb5dA3);
        keepers = IAddressList(_factory.createList());
        maintainers = IAddressList(_factory.createList());
        // List creator i.e. governor can do job of keeper and maintainer.
        keepers.add(governor);
        maintainers.add(governor);
    }

    /**
     * @notice Add given address in provided address list.
     * @dev Use it to add keeper in keepers list and to add address in feeWhitelist
     * @param _listToUpdate address of AddressList contract.
     * @param _addressToAdd address which we want to add in AddressList.
     */
    function addInList(address _listToUpdate, address _addressToAdd) external onlyKeeper {
        require(IAddressList(_listToUpdate).add(_addressToAdd), "add-in-list-failed");
    }

    /**
     * @notice Remove given address from provided address list.
     * @dev Use it to remove keeper from keepers list and to remove address from feeWhitelist
     * @param _listToUpdate address of AddressList contract.
     * @param _addressToRemove address which we want to remove from AddressList.
     */
    function removeFromList(address _listToUpdate, address _addressToRemove) external onlyKeeper {
        require(IAddressList(_listToUpdate).remove(_addressToRemove), "remove-from-list-failed");
    }

    /// @dev Add strategy
    function addStrategy(
        address _strategy,
        uint256 _interestFee,
        uint256 _debtRatio,
        uint256 _debtRate
    ) public onlyGovernor {
        require(_strategy != address(0), "strategy-address-is-zero");
        require(!strategy[_strategy].active, "strategy-already-added");
        totalDebtRatio = totalDebtRatio + _debtRatio;
        require(totalDebtRatio <= MAX_BPS, "totalDebtRatio-above-max_bps");
        require(_interestFee <= MAX_BPS, "interest-fee-above-max_bps");
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

    function migrateStrategy(address _old, address _new) external onlyGovernor {
        require(_new != address(0), "new-address-is-zero");
        require(_old != address(0), "old-address-is-zero");
        require(IStrategy(_new).pool() == address(this), "not-valid-new-strategy");
        require(IStrategy(_old).pool() == address(this), "not-valid-old-strategy");
        require(strategy[_old].active, "strategy-already-migrated");
        require(!strategy[_new].active, "strategy-already-added");
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
        strategy[_old].debtRatio = 0;
        strategy[_old].totalDebt = 0;
        strategy[_old].debtRate = 0;
        strategy[_old].active = false;
        strategy[_new] = _newStrategy;

        IStrategy(_old).migrate(_new);

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
     * @dev Revoke and remove strategy from array. Update withdraw queue.
     * Withdraw queue order should not change after remove.
     * Strategy can be removed only after it has paid all debt.
     * Use migrate strategy if debt is not paid and want to upgrade strat.
     */
    function removeStrategy(uint256 _index) external onlyGovernor {
        address _strategy = strategies[_index];
        require(strategy[_strategy].active, "strategy-not-active");
        require(strategy[_strategy].totalDebt == 0, "strategy-has-debt");
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

    function updateInterestFee(address _strategy, uint256 _interestFee) external onlyGovernor {
        require(_strategy != address(0), "strategy-address-is-zero");
        require(strategy[_strategy].active, "strategy-not-active");
        require(_interestFee <= MAX_BPS, "interest-fee-above-max_bps");
        strategy[_strategy].interestFee = _interestFee;
        emit UpdatedInterestFee(_strategy, _interestFee);
    }

    /**
     * @dev Update debt ratio.  A strategy is retired when debtRatio is 0
     */
    function updateDebtRatio(address _strategy, uint256 _debtRatio) external onlyMaintainer {
        require(strategy[_strategy].active, "strategy-not-active");
        totalDebtRatio = totalDebtRatio - strategy[_strategy].debtRatio + _debtRatio;
        require(totalDebtRatio <= MAX_BPS, "totalDebtRatio-above-max_bps");
        strategy[_strategy].debtRatio = _debtRatio;
        emit UpdatedStrategyDebtParams(_strategy, _debtRatio, strategy[_strategy].debtRate);
    }

    /**
     * @dev Update debtRate per block.
     */
    function updateDebtRate(address _strategy, uint256 _debtRate) external onlyKeeper {
        require(strategy[_strategy].active, "strategy-not-active");
        strategy[_strategy].debtRate = _debtRate;
        emit UpdatedStrategyDebtParams(_strategy, strategy[_strategy].debtRatio, _debtRate);
    }

    /// @dev update withdrawal queue
    function updateWithdrawQueue(address[] memory _withdrawQueue) external onlyMaintainer {
        uint256 _length = _withdrawQueue.length;
        require(_length > 0, "withdrawal-queue-blank");
        require(_length == withdrawQueue.length && _length == strategies.length, "incorrect-withdraw-queue-length");
        for (uint256 i = 0; i < _length; i++) {
            require(strategy[_withdrawQueue[i]].active, "invalid-strategy");
        }
        withdrawQueue = _withdrawQueue;
    }

    ///////////////////////////////////////////////////////////////////////////

    /**
     @dev Strategy call this in regular interval.
     @param _profit yield generated by strategy. Strategy get performance fee on this amount
     @param _loss  Reduce debt ,also reduce debtRatio, increase loss in record.
     @param _payback strategy willing to payback outstanding above debtLimit. no performance fee on this amount. 
      when governance has reduced debtRatio of strategy, strategy will report profit and payback amount separately. 
     */
    function reportEarning(
        uint256 _profit,
        uint256 _loss,
        uint256 _payback
    ) external onlyStrategy {
        require(token.balanceOf(_msgSender()) >= (_profit + _payback), "insufficient-balance-in-strategy");
        if (_loss != 0) {
            _reportLoss(_msgSender(), _loss);
        }

        uint256 _overLimitDebt = _excessDebt(_msgSender());
        uint256 _actualPayback = _min(_overLimitDebt, _payback);
        if (_actualPayback != 0) {
            strategy[_msgSender()].totalDebt -= _actualPayback;
            totalDebt -= _actualPayback;
        }
        uint256 _creditLine = _availableCreditLimit(_msgSender());
        if (_creditLine != 0) {
            strategy[_msgSender()].totalDebt += _creditLine;
            totalDebt += _creditLine;
        }
        uint256 _totalPayback = _profit + _actualPayback;
        if (_totalPayback < _creditLine) {
            token.safeTransfer(_msgSender(), _creditLine - _totalPayback);
        } else if (_totalPayback > _creditLine) {
            token.safeTransferFrom(_msgSender(), address(this), _totalPayback - _creditLine);
        }
        if (_profit != 0) {
            strategy[_msgSender()].totalProfit += _profit;
            _transferInterestFee(_profit);
        }
        emit EarningReported(
            _msgSender(),
            _profit,
            _loss,
            _actualPayback,
            strategy[_msgSender()].totalDebt,
            totalDebt,
            _creditLine
        );
    }

    /**
     * @dev Transfer given ERC20 token to feeCollector
     * @param _fromToken Token address to sweep
     */
    function sweepERC20(address _fromToken) external virtual onlyKeeper {
        require(_fromToken != address(token), "not-allowed-to-sweep");
        require(feeCollector != address(0), "fee-collector-not-set");
        IERC20(_fromToken).safeTransfer(feeCollector, IERC20(_fromToken).balanceOf(address(this)));
    }

    /**
    @dev debt above current debt limit
    */
    function excessDebt(address _strategy) external view returns (uint256) {
        return _excessDebt(_strategy);
    }

    /**
    @dev available credit limit is calculated based on current debt of pool and strategy, current debt limit of pool and strategy. 
    // credit available = min(pool's debt limit, strategy's debt limit, max debt per rebalance)
    // when some strategy do not pay back outstanding debt, this impact credit line of other strategy if totalDebt of pool >= debtLimit of pool
    */
    function availableCreditLimit(address _strategy) external view returns (uint256) {
        return _availableCreditLimit(_strategy);
    }

    /**
     * @notice Get total debt of given strategy
     */
    function totalDebtOf(address _strategy) external view returns (uint256) {
        return strategy[_strategy].totalDebt;
    }

    /// @dev Returns total value of vesper pool, in terms of collateral token
    function totalValue() public view override returns (uint256) {
        return totalDebt + tokensHere();
    }

    function _withdrawCollateral(uint256 _amount) internal virtual {
        // Withdraw amount from queue
        uint256 _debt;
        uint256 _balanceAfter;
        uint256 _balanceBefore;
        uint256 _amountWithdrawn;
        uint256 _amountNeeded = _amount;
        uint256 _totalAmountWithdrawn;
        for (uint256 i; i < withdrawQueue.length; i++) {
            _debt = strategy[withdrawQueue[i]].totalDebt;
            if (_debt == 0) {
                continue;
            }
            if (_amountNeeded > _debt) {
                // Should not withdraw more than current debt of strategy.
                _amountNeeded = _debt;
            }
            _balanceBefore = tokensHere();
            //solhint-disable no-empty-blocks
            try IStrategy(withdrawQueue[i]).withdraw(_amountNeeded) {} catch {
                continue;
            }
            _balanceAfter = tokensHere();
            _amountWithdrawn = _balanceAfter - _balanceBefore;
            // Adjusting totalDebt. Assuming that during next reportEarning(), strategy will report loss if amountWithdrawn < _amountNeeded
            strategy[withdrawQueue[i]].totalDebt -= _amountWithdrawn;
            totalDebt -= _amountWithdrawn;
            _totalAmountWithdrawn += _amountWithdrawn;
            if (_totalAmountWithdrawn >= _amount) {
                // withdraw done
                break;
            }
            _amountNeeded = _amount - _totalAmountWithdrawn;
        }
    }

    /**
     * @dev Before burning hook.
     * withdraw amount from strategies
     */
    function _beforeBurning(uint256 _share) internal override returns (uint256 actualWithdrawn) {
        uint256 _amount = (_share * pricePerShare()) / 1e18;
        uint256 _balanceNow = tokensHere();
        if (_amount > _balanceNow) {
            _withdrawCollateral(_amount - _balanceNow);
            _balanceNow = tokensHere();
        }
        actualWithdrawn = _balanceNow < _amount ? _balanceNow : _amount;
    }

    /**
    @dev when a strategy report loss, its debtRatio decrease to get fund back quickly.
    */
    function _reportLoss(address _strategy, uint256 _loss) internal {
        uint256 _currentDebt = strategy[_strategy].totalDebt;
        require(_currentDebt >= _loss, "loss-too-high");
        strategy[_strategy].totalLoss += _loss;
        strategy[_strategy].totalDebt -= _loss;
        totalDebt -= _loss;
        uint256 _deltaDebtRatio = _min((_loss * MAX_BPS) / totalValue(), strategy[_strategy].debtRatio);
        strategy[_strategy].debtRatio -= _deltaDebtRatio;
        totalDebtRatio -= _deltaDebtRatio;
    }

    function _excessDebt(address _strategy) internal view returns (uint256) {
        uint256 _currentDebt = strategy[_strategy].totalDebt;
        if (stopEverything) {
            return _currentDebt;
        }
        uint256 _maxDebt = (strategy[_strategy].debtRatio * totalValue()) / MAX_BPS;
        return _currentDebt > _maxDebt ? (_currentDebt - _maxDebt) : 0;
    }

    function _availableCreditLimit(address _strategy) internal view returns (uint256) {
        if (stopEverything) {
            return 0;
        }
        uint256 _totalValue = totalValue();
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
        _available = _min(_min(tokensHere(), _available), _poolDebtLimit - totalDebt);
        _available = _min(
            (block.number - strategy[_strategy].lastRebalance) * strategy[_strategy].debtRate,
            _available
        );
        return _available;
    }

    /**
    @dev strategy get interest fee in pool share token
    */
    function _transferInterestFee(uint256 _profit) internal {
        uint256 _fee = (_profit * strategy[_msgSender()].interestFee) / MAX_BPS;
        if (_fee != 0) {
            _fee = _calculateShares(_fee);
            _mint(_msgSender(), _fee);
        }
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
