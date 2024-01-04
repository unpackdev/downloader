// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./StrategyCurveBase.sol";
import "./IVault.sol";
import "./ICurveFi.sol";

/**
 * @dev Strategy for HBTC on Curve's HBTC pool.
 * Important tokens:
 * - want: HBTC
 * - lp: hbtcCrv
 * - lpVault: hbtcCrvv
 */
contract StrategyHbtcCurveHbtc is StrategyCurveBase {
    
    // Pool parameters
    address public constant HBTCCRV_VAULT = address(0x68A8aaf01892107E635d5DE1564b0D0a3FE39406); // hbtcCrv vault
    address public constant HBTC_SWAP = address(0x4CA9b3063Ec5866A4B82E437059D2C43d1be596F); // HBTC swap

    constructor(address _vault) StrategyCurveBase(_vault, HBTCCRV_VAULT, HBTC_SWAP) public {
    }

    /**
     * @dev Invests the free token balance in the strategy.
     * Special handling for HBTC since HBTC does not allow setting allowance to zero!
     */
    function deposit() public override authorized {
        IERC20Upgradeable want = IERC20Upgradeable(token());
        uint256 _want = want.balanceOf(address(this));
        if (_want > 0) {
            want.safeApprove(curve, _want);
            uint256 v = _want.mul(1e18).mul(_getLpRate()).div(ICurveFi(curve).get_virtual_price());
            ICurveFi(curve).add_liquidity([_want, 0], v.mul(PERCENT_MAX.sub(slippage)).div(PERCENT_MAX));
        }

        IERC20Upgradeable lp = IERC20Upgradeable(IVault(lpVault).token());
        uint256 _lp = lp.balanceOf(address(this));
        if (_lp > 0) {
            lp.safeApprove(lpVault, 0);
            lp.safeApprove(lpVault, _lp);
            IVault(lpVault).deposit(_lp);
        }
    }

    /**
     * @dev Withdraws the want token from Curve by burning lp token.
     * @param _lp Amount of LP token to burn.
     * @param _minAmount Minimum want token to receive.
     */
    function _withdrawFromCurve(uint256 _lp, uint256 _minAmount) internal override {
        ICurveFi(curve).remove_liquidity_one_coin(_lp, 0, _minAmount);
    }
}