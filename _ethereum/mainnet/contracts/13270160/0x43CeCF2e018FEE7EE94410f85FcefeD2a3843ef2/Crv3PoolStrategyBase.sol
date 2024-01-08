// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IVesperPool.sol";
import "./Strategy.sol";
import "./Crv3x.sol";

/// @title This strategy will deposit collateral token in Curve 3Pool and earn interest.
abstract contract Crv3PoolStrategyBase is Crv3x, Strategy {
    using SafeERC20 for IERC20;

    mapping(address => bool) internal reservedToken;

    address public immutable threePool;
    address public immutable threeCrv;
    address public immutable gauge;

    uint256 public immutable collIdx;
    uint256 public usdRate;
    uint256 public usdRateTimestamp;
    bool public depositError;

    uint256 public crvSlippage = 10; // 10000 is 100%; 10 is 0.1%

    event UpdatedCrvSlippage(uint256 oldCrvSlippage, uint256 newCrvSlippage);

    event DepositFailed(string reason);

    constructor(
        address _pool,
        address _threePool,
        address _threeCrv,
        address _gauge,
        address _swapManager,
        uint256 _collateralIdx
    )
        Crv3x(_threePool, _threeCrv, _gauge) // 3Pool Manager
        Strategy(_pool, _swapManager, _threeCrv)
    {
        require(_collateralIdx < N, "invalid-collateral");
        threePool = _threePool;
        threeCrv = _threeCrv;
        gauge = _gauge;
        reservedToken[_threeCrv] = true;
        reservedToken[CRV] = true;
        collIdx = _collateralIdx;
    }

    function updateCrvSlippage(uint256 _newCrvSlippage) external onlyGovernor {
        require(_newCrvSlippage < 10000, "invalid-slippage-value");
        emit UpdatedCrvSlippage(crvSlippage, _newCrvSlippage);
        crvSlippage - _newCrvSlippage;
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view override returns (bool) {
        return reservedToken[_token];
    }

    /**
     * @notice Calculate total value of asset under management
     * @dev Report total value in collateral token
     */
    function totalValue() public view virtual override returns (uint256 _value) {
        uint256 claimable = claimableRewards();
        uint256 rewardAsCollateral;
        if (claimable != 0) {
            (, rewardAsCollateral, ) = swapManager.bestOutputFixedInput(CRV, address(collateralToken), claimable);
        }
        _value =
            collateralToken.balanceOf(address(this)) +
            convertFrom18(_calcAmtOutAfterSlippage(getLpValue(totalLp()), crvSlippage)) +
            rewardAsCollateral;
    }

    function _setupOracles() internal virtual override {
        swapManager.createOrUpdateOracle(CRV, WETH, oraclePeriod, oracleRouterIdx);
        for (uint256 i = 0; i < N; i++) {
            swapManager.createOrUpdateOracle(
                IStableSwap3xUnderlying(threePool).coins(i),
                WETH,
                oraclePeriod,
                oracleRouterIdx
            );
        }
    }

    // given the rates of 3 stablecoins compared with a common denominator
    // return the lowest divided by the highest
    function _getSafeUsdRate() internal returns (uint256) {
        // use a stored rate if we've looked it up recently
        if (usdRateTimestamp > block.timestamp - oraclePeriod && usdRate != 0) return usdRate;
        // otherwise, calculate a rate and store it.
        uint256 lowest;
        uint256 highest;
        for (uint256 i = 0; i < N; i++) {
            // get the rate for $1
            (uint256 rate, bool isValid) = _consultOracle(coins[i], WETH, 10**coinDecimals[i]);
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

    function _approveToken(uint256 _amount) internal virtual override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(crvPool), _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(CRV).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
        IERC20(crvLp).safeApprove(crvGauge, _amount);
    }

    function _reinvest() internal override {
        depositError = false;
        uint256 amt = collateralToken.balanceOf(address(this));
        depositError = !_depositToCurve(amt);
        _stakeAllLp();
    }

    function _depositToCurve(uint256 amt) internal virtual returns (bool) {
        if (amt != 0) {
            uint256[3] memory depositAmounts;
            depositAmounts[collIdx] = amt;
            uint256 expectedOut =
                _calcAmtOutAfterSlippage(
                    IStableSwap3xUnderlying(address(crvPool)).calc_token_amount(depositAmounts, true),
                    crvSlippage
                );
            uint256 minLpAmount =
                ((amt * _getSafeUsdRate()) / crvPool.get_virtual_price()) * 10**(18 - coinDecimals[collIdx]);
            if (expectedOut > minLpAmount) minLpAmount = expectedOut;
            // solhint-disable-next-line no-empty-blocks
            try IStableSwap3xUnderlying(address(crvPool)).add_liquidity(depositAmounts, minLpAmount) {} catch Error(
                string memory reason
            ) {
                emit DepositFailed(reason);
                return false;
            }
        }
        return true;
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
        _unstakeLp(unstakeAmt);
        uint256 minAmtOut =
            convertFrom18(
                (lpToWithdraw * _calcAmtOutAfterSlippage(_minimumLpPrice(_getSafeUsdRate()), crvSlippage)) / 1e18
            );
        _withdrawAsFromCrvPool(lpToWithdraw, minAmtOut, i);
        toWithdraw = collateralToken.balanceOf(address(this));
        if (toWithdraw > _amount) toWithdraw = _amount;
    }

    /**
     * @notice some strategy may want to prepare before doing migration. 
        Example In Maker old strategy want to give vault ownership to new strategy
     */
    function _beforeMigration(
        address /*_newStrategy*/
    ) internal override {
        _unstakeAllLp();
    }

    function _claimRewardsAndConvertTo(address _toToken) internal virtual override {
        _claimCrv();
        uint256 amt = IERC20(CRV).balanceOf(address(this));
        if (amt != 0) {
            address[] memory path = new address[](3);
            path[0] = CRV;
            path[1] = WETH;
            path[2] = _toToken;
            uint256 minAmtOut =
                (swapSlippage != 10000) ? _calcAmtOutAfterSlippage(_getOracleRate(path, amt), swapSlippage) : 1;
            _safeSwap(CRV, _toToken, amt, minAmtOut);
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

    function _realizeLoss(uint256 _totalDebt) internal view override returns (uint256 _loss) {
        uint256 _collateralBalance = convertFrom18(_calcAmtOutAfterSlippage(getLpValue(totalLp()), crvSlippage));
        if (_collateralBalance < _totalDebt) {
            _loss = _totalDebt - _collateralBalance;
        }
    }

    function _realizeGross(uint256 _totalDebt)
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _toUnstake
        )
    {
        uint256 baseline = collateralToken.balanceOf(address(this));
        _claimRewardsAndConvertTo(address(collateralToken));
        uint256 newBalance = collateralToken.balanceOf(address(this));
        _profit = newBalance - baseline;

        uint256 _collateralBalance =
            baseline + convertFrom18(_calcAmtOutAfterSlippage(getLpValue(totalLp()), crvSlippage));
        if (_collateralBalance > _totalDebt) {
            _profit += _collateralBalance - _totalDebt;
        } else {
            _loss = _totalDebt - _collateralBalance;
        }

        if (_profit > _loss) {
            _profit = _profit - _loss;
            _loss = 0;
            if (_profit > newBalance) _toUnstake = _profit - newBalance;
        } else {
            _loss = _loss - _profit;
            _profit = 0;
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

    // Unused
    /* solhint-disable no-empty-blocks */

    function _liquidate(uint256 _excessDebt) internal override returns (uint256 _payback) {}

    function _realizeProfit(uint256 _totalDebt) internal override returns (uint256 _profit) {}
}
