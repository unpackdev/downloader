// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IVesperPool.sol";
import "./Strategy.sol";
import "./Crv3PoolMgr.sol";

/// @title This strategy will deposit collateral token in Curve 3Pool and earn interest.
abstract contract Crv3PoolStrategy is Crv3PoolMgr, Strategy {
    using SafeERC20 for IERC20;

    mapping(address => bool) private reservedToken;
    address[] private oracles;

    uint256 public constant ORACLE_PERIOD = 3600; // 1h
    uint256 public immutable collIdx;
    uint256 public usdRate;
    uint256 public usdRateTimestamp;
    bool public depositError;

    uint256 public depositSlippage = 500; // 10000 is 100%
    event UpdatedDepositSlippage(uint256 oldSlippage, uint256 newSlippage);
    event DepositFailed(string reason);

    constructor(
        address _pool,
        address _swapManager,
        uint256 _collateralIdx
    ) Strategy(_pool, _swapManager, THREECRV) Crv3PoolMgr() {
        require(_collateralIdx < COINS.length, "Invalid collateral for 3Pool");
        require(COIN_ADDRS[_collateralIdx] == address(IVesperPool(_pool).token()), "Collateral does not match");
        reservedToken[THREECRV] = true;
        reservedToken[CRV] = true;
        collIdx = _collateralIdx;
        _setupOracles();
    }

    function updateDepositSlippage(uint256 _newSlippage) external onlyGovernor {
        require(_newSlippage != depositSlippage, "same-slippage");
        require(_newSlippage < 10000, "invalid-slippage-value");
        emit UpdatedDepositSlippage(depositSlippage, _newSlippage);
        depositSlippage = _newSlippage;
    }

    function _setupOracles() internal {
        oracles.push(swapManager.createOrUpdateOracle(CRV, WETH, ORACLE_PERIOD, 0));
        for (uint256 i = 0; i < N; i++) {
            oracles.push(swapManager.createOrUpdateOracle(COIN_ADDRS[i], WETH, ORACLE_PERIOD, 0));
        }
    }

    function _estimateSlippage(uint256 _amount, uint256 _slippage) internal pure returns (uint256) {
        return (_amount * (10000 - _slippage)) / (10000);
    }

    function _consultOracle(
        address _from,
        address _to,
        uint256 _amt
    ) internal returns (uint256, bool) {
        // from, to, amountIn, period, router
        (uint256 rate, uint256 lastUpdate, ) = swapManager.consult(_from, _to, _amt, ORACLE_PERIOD, 0);
        // We're looking at a TWAP ORACLE with a 1 hr Period that has been updated within the last hour
        if ((lastUpdate > (block.timestamp - ORACLE_PERIOD)) && (rate != 0)) return (rate, true);
        return (0, false);
    }

    // given the rates of 3 stablecoins compared with a common denominator
    // return the lowest divided by the highest
    function _getSafeUsdRate() internal returns (uint256) {
        // use a stored rate if we've looked it up recently
        if (usdRateTimestamp > block.timestamp - ORACLE_PERIOD && usdRate != 0) return usdRate;
        // otherwise, calculate a rate and store it.
        uint256 lowest;
        uint256 highest;
        for (uint256 i = 0; i < N; i++) {
            // get the rate for $1
            (uint256 rate, bool isValid) = _consultOracle(COIN_ADDRS[i], WETH, 10**DECIMALS[i]);
            if (isValid) {
                if (lowest == 0 || rate < lowest) {
                    lowest = rate;
                }
                if (highest < rate) {
                    highest = rate;
                }
            }
        }
        // We only need to check one of them because if a single valid rate is returned,
        // highest == lowest and highest > 0 && lowest > 0
        require(lowest != 0, "no-oracle-rates");
        usdRateTimestamp = block.timestamp;
        usdRate = (lowest * 1e18) / highest;
        return usdRate;
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view override returns (bool) {
        return reservedToken[_token];
    }

    function _approveToken(uint256 _amount) internal override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(crvPool, _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(CRV).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
        IERC20(crvLp).safeApprove(crvGauge, _amount);
    }

    function _reinvest() internal override {
        depositError = false;
        uint256 amt = collateralToken.balanceOf(address(this));
        if (amt != 0) {
            uint256[3] memory depositAmounts;
            depositAmounts[collIdx] = amt;
            uint256 minLpAmount =
                _estimateSlippage((amt * 1e18) / _minimumLpPrice(_getSafeUsdRate()), depositSlippage) *
                    10**(18 - DECIMALS[collIdx]);
            // solhint-disable-next-line no-empty-blocks
            try THREEPOOL.add_liquidity(depositAmounts, minLpAmount) {} catch Error(string memory reason) {
                depositError = true;
                emit DepositFailed(reason);
            }
            _stakeAllLpToGauge();
        }
    }

    function _withdraw(uint256 _amount) internal override {
        // This adds some gas but will save loss on exchange fees
        uint256 balanceHere = collateralToken.balanceOf(address(this));
        if (_amount > balanceHere) {
            _unstakeAndWithdrawAsCollateral(_amount - balanceHere);
        }
        collateralToken.safeTransfer(pool, _amount);
    }

    function _unstakeAndWithdrawAsCollateral(uint256 _amount) internal returns (uint256 toWithdraw) {
        if (_amount == 0) return 0;
        uint256 i = collIdx;
        (uint256 lpToWithdraw, uint256 unstakeAmt) = calcWithdrawLpAs(_amount, i);
        _unstakeLpFromGauge(unstakeAmt);
        uint256 minAmtOut = (convertFrom18(_minimumLpPrice(_getSafeUsdRate())) * lpToWithdraw) / 1e18;
        _withdrawAsFromCrvPool(lpToWithdraw, minAmtOut, i);
        toWithdraw = collateralToken.balanceOf(address(this));
        if (toWithdraw > _amount) toWithdraw = _amount;
    }

    /**
     * @notice Calculate total value of asset under management
     * @dev Report total value in collateral token
     */
    function totalValue() external view override returns (uint256 _value) {
        _value = collateralToken.balanceOf(address(this)) + getLpValue(totalLp());
    }

    /**
     * @notice some strategy may want to prepare before doing migration. 
        Example In Maker old strategy want to give vault ownership to new strategy
     */
    function _beforeMigration(
        address /*_newStrategy*/
    ) internal override {
        _unstakeAllLpFromGauge();
    }

    function _claimRewardsAndConvertTo(address _toToken) internal override {
        _claimCrv();
        uint256 amt = IERC20(CRV).balanceOf(address(this));
        if (amt != 0) {
            _safeSwap(CRV, _toToken, amt, 1);
        }
    }

    /**
     * @notice Withdraw collateral to payback excess debt in pool.
     * @param _excessDebt Excess debt of strategy in collateral token
     * @param _extra additional amount to unstake and withdraw, in collateral token
     * @return _payback amount in collateral token. Usually it is equal to excess debt.
     */

    function _liquidate(uint256 _excessDebt, uint256 _extra) internal returns (uint256 _payback) {
        _payback = _unstakeAndWithdrawAsCollateral(_excessDebt + _extra);
        // we dont want to return a value greater than we need to
        if (_payback > _excessDebt) _payback = _excessDebt;
    }

    function _liquidate(uint256 _excessDebt) internal override returns (uint256 _payback) {}

    function _realizeProfit(uint256 _totalDebt) internal override returns (uint256 _profit) {}

    function _realizeLoss(uint256 _totalDebt) internal view override returns (uint256 _loss) {
        uint256 _collateralBalance = convertFrom18(estimateFeeImpact(getLpValue(totalLp())));
        if (_collateralBalance < _totalDebt) {
            _loss = _totalDebt - _collateralBalance;
        }
    }

    function _realizeGross(uint256 _totalDebt)
        internal
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _toUnstake
        )
    {
        uint256 baseline = collateralToken.balanceOf(address(this));
        _claimRewardsAndConvertTo(address(collateralToken));
        uint256 _collateralBalance = convertFrom18(estimateFeeImpact(getLpValue(totalLp())));
        if (_collateralBalance > _totalDebt) {
            _toUnstake = _collateralBalance - _totalDebt;
        } else {
            _loss = _totalDebt - _collateralBalance;
        }

        _profit = collateralToken.balanceOf(address(this)) + _toUnstake - baseline;
        if (_profit > _loss) {
            _profit = _profit - _loss;
            _loss = 0;
        } else {
            _loss = _loss - _profit;
            _profit = 0;
            _toUnstake = 0;
        }
    }

    function _generateReport()
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));
        uint256 _toUnstake;
        (_profit, _loss, _toUnstake) = _realizeGross(_totalDebt);
        // only make call to unstake and withdraw once
        _payback = _liquidate(_excessDebt, _toUnstake);
    }

    function rebalance() external override onlyKeeper {
        (uint256 _profit, uint256 _loss, uint256 _payback) = _generateReport();
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        _reinvest();
        if (!depositError) {
            uint256 depositLoss = _realizeLoss(IVesperPool(pool).totalDebtOf(address(this)));
            if (depositLoss > _loss) IVesperPool(pool).reportLoss(depositLoss - _loss);
        }
    }
}
