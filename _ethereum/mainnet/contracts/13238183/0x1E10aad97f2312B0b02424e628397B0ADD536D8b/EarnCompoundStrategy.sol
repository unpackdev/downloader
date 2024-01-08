// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CompoundStrategy.sol";
import "./Earn.sol";
import "./IPoolRewards.sol";

/// @title This strategy will deposit collateral token in Compound and earn drip in an another token.
abstract contract EarnCompoundStrategy is CompoundStrategy, Earn {
    using SafeERC20 for IERC20;

    // solhint-disable no-empty-blocks
    constructor(
        address _pool,
        address _swapManager,
        address _receiptToken,
        address _dripToken
    ) CompoundStrategy(_pool, _swapManager, _receiptToken) Earn(_dripToken) {}

    // solhint-enable no-empty-blocks

    function totalValueCurrent() external virtual override(Strategy, CompoundStrategy) returns (uint256 _totalValue) {
        _claimComp();
        _totalValue = _calculateTotalValue(IERC20(COMP).balanceOf(address(this)));
    }

    function _setupOracles() internal override(Strategy, CompoundStrategy) {
        CompoundStrategy._setupOracles();
    }

    function _claimRewardsAndConvertTo(address _toToken) internal override(Strategy, CompoundStrategy) {
        CompoundStrategy._claimRewardsAndConvertTo(_toToken);
    }

    function _realizeProfit(uint256 _totalDebt)
        internal
        virtual
        override(Strategy, CompoundStrategy)
        returns (uint256)
    {
        _claimRewardsAndConvertTo(address(dripToken));
        uint256 _collateralBalance = _convertToCollateral(cToken.balanceOf(address(this)));
        if (_collateralBalance > _totalDebt) {
            _withdrawHere(_collateralBalance - _totalDebt);
        }
        _convertCollateralToDrip();
        _forwardEarning();
        return 0;
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override(Strategy, CompoundStrategy) {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(cToken), _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(COMP).safeApprove(address(swapManager.ROUTERS(i)), _amount);
            collateralToken.safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }
}
