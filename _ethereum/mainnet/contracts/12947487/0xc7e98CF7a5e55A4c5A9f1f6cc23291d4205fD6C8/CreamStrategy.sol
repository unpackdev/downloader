// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CompoundStrategy.sol";

/// @title This strategy will deposit collateral token in C.R.E.A.M. and earn interest.
abstract contract CreamStrategy is CompoundStrategy {
    using SafeERC20 for IERC20;

    // solhint-disable no-empty-blocks
    constructor(
        address _pool,
        address _swapManager,
        address _receiptToken
    ) CompoundStrategy(_pool, _swapManager, _receiptToken) {}

    // solhint-enable no-empty-blocks

    /**
     * @notice Calculate total value using underlying token
     * @dev Report total value in collateral token
     */
    function totalValue() external view override returns (uint256 _totalValue) {
        _totalValue = _convertToCollateral(cToken.balanceOf(address(this)));
    }

    function isReservedToken(address _token) public view override returns (bool) {
        return _token == address(cToken);
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(cToken), _amount);
    }

    // solhint-disable-next-line
    function _beforeMigration(address _newStrategy) internal override {}

    /**
     * @notice Calculate earning and withdraw it from C.R.E.A.M.
     * @dev If somehow we got some collateral token in strategy then we want to
     *  include those in profit. That's why we used 'return' outside 'if' condition.
     *  Since there aren't token rewards here, we call accrueInterst
     *  to make sure we get the maximum accrued interest on rebalance
     * @param _totalDebt Total collateral debt of this strategy
     * @return profit in collateral token
     */
    function _realizeProfit(uint256 _totalDebt) internal override returns (uint256) {
        cToken.accrueInterest();
        uint256 _collateralBalance = _convertToCollateral(cToken.balanceOf(address(this)));

        if (_collateralBalance > _totalDebt) {
            _withdrawHere(_collateralBalance - _totalDebt);
        }
        return collateralToken.balanceOf(address(this));
    }
}
