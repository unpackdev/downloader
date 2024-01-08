// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./AaveCore.sol";
import "./Strategy.sol";

/// @dev This strategy will deposit collateral token in Aave and earn interest.
abstract contract AaveStrategy is Strategy, AaveCore {
    using SafeERC20 for IERC20;

    //solhint-disable no-empty-blocks
    constructor(
        address _pool,
        address _swapManager,
        address _receiptToken
    ) Strategy(_pool, _swapManager, _receiptToken) AaveCore(_receiptToken) {}

    //solhint-enable

    /// @notice Initiate cooldown to unstake aave.
    function startCooldown() external onlyKeeper returns (bool) {
        return _startCooldown();
    }

    /// @notice Unstake Aave from stakedAave contract
    function unstakeAave() external onlyKeeper {
        _unstakeAave();
    }

    /**
     * @notice Report total value
     * @dev aToken and collateral are 1:1
     */
    function totalValue() external view virtual override returns (uint256) {
        uint256 _totalAave = _totalAave();
        if (_totalAave == 0) {
            // As there is no AAVE balance return aToken balance as totalValue.
            return aToken.balanceOf(address(this));
        }
        // Get collateral value of total aave rewards
        (, uint256 _aaveAsCollateral, ) = swapManager.bestOutputFixedInput(AAVE, address(collateralToken), _totalAave);
        // Total value = aave as collateral + aToken balance
        return _aaveAsCollateral + aToken.balanceOf(address(this));
    }

    function isReservedToken(address _token) public view override returns (bool) {
        return _isReservedToken(_token);
    }

    /// @notice Large approval of token
    function _approveToken(uint256 _amount) internal override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(aaveLendingPool), _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(AAVE).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    /**
     * @notice Transfer StakeAave to newStrategy
     * @param _newStrategy Address of newStrategy
     */
    function _beforeMigration(address _newStrategy) internal override {
        uint256 _stkAaveAmount = stkAAVE.balanceOf(address(this));
        if (_stkAaveAmount != 0) {
            IERC20(stkAAVE).safeTransfer(_newStrategy, _stkAaveAmount);
        }
    }

    /// @notice Claim Aave rewards and convert to _toToken.
    function _claimRewardsAndConvertTo(address _toToken) internal override {
        uint256 _aaveAmount = _claimAave();
        if (_aaveAmount > 0) {
            _safeSwap(AAVE, _toToken, _aaveAmount, 1);
        }
    }

    /// @notice Withdraw collateral to payback excess debt
    function _liquidate(uint256 _excessDebt) internal override returns (uint256 _payback) {
        if (_excessDebt != 0) {
            _payback = _safeWithdraw(address(collateralToken), address(this), _excessDebt);
        }
    }

    /**
     * @notice Calculate earning and withdraw it from Aave.
     * @dev If somehow we got some collateral token in strategy then we want to
     *  include those in profit. That's why we used 'return' outside 'if' condition.
     * @param _totalDebt Total collateral debt of this strategy
     * @return profit in collateral token
     */
    function _realizeProfit(uint256 _totalDebt) internal override returns (uint256) {
        _claimRewardsAndConvertTo(address(collateralToken));
        uint256 _aTokenBalance = aToken.balanceOf(address(this));
        if (_aTokenBalance > _totalDebt) {
            _withdraw(address(collateralToken), address(this), _aTokenBalance - _totalDebt);
        }
        return collateralToken.balanceOf(address(this));
    }

    /**
     * @notice Calculate realized loss.
     * @return _loss Realized loss in collateral token
     */
    function _realizeLoss(uint256 _totalDebt) internal view override returns (uint256 _loss) {
        uint256 _aTokenBalance = aToken.balanceOf(address(this));
        if (_aTokenBalance < _totalDebt) {
            _loss = _totalDebt - _aTokenBalance;
        }
    }

    /// @notice Deposit collateral in Aave
    function _reinvest() internal override {
        _deposit(address(collateralToken), collateralToken.balanceOf(address(this)));
    }

    /**
     * @notice Withdraw given amount of collateral from Aave to pool
     * @param _amount Amount of collateral to withdraw.
     */
    function _withdraw(uint256 _amount) internal override {
        _safeWithdraw(address(collateralToken), pool, _amount);
    }
}
