// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./ConvexFactoryPlainPoolStrategy.sol";
import "./ICurveDeposit_3token.sol";
import "./IERC20Detailed.sol";

import "./SafeERC20Upgradeable.sol";

contract ConvexStrategyPlainPool3Token is ConvexFactoryPlainPoolStrategy {
    using SafeERC20Upgradeable for IERC20Detailed;

    /// @notice curve N_COINS for the pool
    uint256 public constant CURVE_UNDERLYINGS_SIZE = 3;

    /// @return size of the curve deposit array
    function _curveUnderlyingsSize() internal pure override returns (uint256) {
        return CURVE_UNDERLYINGS_SIZE;
    }

    /// @notice Deposits in Curve Metapools for 3 tokens (eg. 3eur)
    function _depositInCurve(uint256 _minLpTokens) internal override {
        IERC20Detailed _deposit = IERC20Detailed(curveDeposit);
        uint256 _balance = _deposit.balanceOf(address(this));
        address _pool = curveLpToken;

        _deposit.safeApprove(_pool, 0);
        _deposit.safeApprove(_pool, _balance);

        // we can accept 0 as minimum, this will be called only by trusted roles
        uint256[3] memory _depositArray;
        _depositArray[depositPosition] = _balance;
        ICurveDeposit_3token(_pool).add_liquidity(_depositArray, _minLpTokens);
    }
}
