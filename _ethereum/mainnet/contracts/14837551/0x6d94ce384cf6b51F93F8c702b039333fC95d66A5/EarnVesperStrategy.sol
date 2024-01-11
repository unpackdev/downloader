// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "./Earn.sol";
import "./VesperStrategy.sol";
import "./IVesperPool.sol";
import "./Math.sol";

/// @title This Earn strategy will deposit collateral token in a Vesper Grow Pool
/// and converts the yield to another Drip Token
// solhint-disable no-empty-blocks
contract EarnVesperStrategy is VesperStrategy, Earn {
    using SafeERC20 for IERC20;

    constructor(
        address _pool,
        address _swapManager,
        address _receiptToken,
        address _dripToken,
        address _vsp,
        string memory _name
    ) VesperStrategy(_pool, _swapManager, _receiptToken, _vsp, _name) Earn(_dripToken) {}

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override(VesperStrategy, Strategy) {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(vToken), _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(vsp).safeApprove(address(swapManager.ROUTERS(i)), _amount);
            collateralToken.safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    /**
     * @notice Generate report for pools accounting and also send profit and any payback to pool.
     * @dev Claim rewardToken and convert to collateral.
     */
    function _generateReport()
        internal
        virtual
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

        _claimRewardsAndConvertTo(address(collateralToken));
        uint256 _investedCollateral = _getCollateralBalance();
        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _totalCollateral = _investedCollateral + _collateralHere;
        uint256 _profit;
        if (_totalCollateral > _totalDebt) {
            _profit = _totalCollateral - _totalDebt;
        }
        uint256 _profitAndExcessDebt = _profit + _excessDebt;
        if (_collateralHere < _profitAndExcessDebt) {
            uint256 _totalAmountToWithdraw = Math.min((_profitAndExcessDebt - _collateralHere), _investedCollateral);
            if (_totalAmountToWithdraw > 0) {
                vToken.withdraw(_convertToShares(_totalAmountToWithdraw));
                _collateralHere = collateralToken.balanceOf(address(this));
            }
        }

        // Min of available collateral and _profit is actual profit at this point
        _profit = Math.min(_collateralHere, _profit);
        _handleProfit(_profit);
        uint256 _payback;
        if (_excessDebt > 0) {
            _payback = Math.min(collateralToken.balanceOf(address(this)), _excessDebt);
        }
        // Earn always report 0 profit and 0 loss.
        return (0, 0, _payback);
    }

    /// @notice Claim VSP rewards in underlying Grow Pool, if any
    function _claimRewardsAndConvertTo(address _toToken) internal virtual override(VesperStrategy, Strategy) {
        VesperStrategy._claimRewardsAndConvertTo(_toToken);
    }
}
