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
 * @dev Strategy for WBTC on Curve's OBTC pool.
 * Important tokens:
 * - want: WBTC
 * - lp: obtcCrv
 * - lpVault: obtcCrvv
 */
contract StrategyWbtcCurveObtc is StrategyCurveBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Pool parameters
    address public constant OBTCCRV_VAULT = address(0xa73b91094304cd7bd1e67a839f63e287B29c0f65); // obtcCrv vault
    address public constant OBTC_SWAP = address(0xd81dA8D904b52208541Bade1bD6595D8a251F8dd); // OBTC swap
    address public constant OBTC_DEPOSIT = address(0xd5BCf53e2C81e1991570f33Fa881c49EEa570C8D); // OBTC deposit

    constructor(address _vault) StrategyCurveBase(_vault, OBTCCRV_VAULT, OBTC_SWAP) public {
    }

    /**
     * @dev Invests the free token balance in the strategy.
     * Special handling for WBTC's oBTC pool strategy since WBTC should be deposited via oBTC deposit!
     */
    function deposit() public virtual override authorized {
        IERC20Upgradeable want = IERC20Upgradeable(token());
        uint256 _want = want.balanceOf(address(this));
        if (_want > 0) {
            want.safeApprove(OBTC_DEPOSIT, 0);
            want.safeApprove(OBTC_DEPOSIT, _want);
            uint256 v = _want.mul(1e18).mul(_getLpRate()).div(ICurveFi(curve).get_virtual_price());
            ICurveFi(OBTC_DEPOSIT).add_liquidity([0, 0, _want, 0], v.mul(PERCENT_MAX.sub(slippage)).div(PERCENT_MAX));
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
     * @dev Withdraws one token from the Curve swap.
     * Special handling for WBTC's oBTC pool strategy since WBTC should be withdrawn via oBTC deposit!
     * @param _lp Amount of LP token to withdraw.
     */
    function _withdrawOne(uint256 _lp) internal override returns (uint256) {
        IERC20Upgradeable want = IERC20Upgradeable(token());
        uint256 _before = want.balanceOf(address(this));

        IERC20Upgradeable lp = IERC20Upgradeable(IVault(lpVault).token());
        lp.safeApprove(OBTC_DEPOSIT, 0);
        lp.safeApprove(OBTC_DEPOSIT, _lp);
        ICurveFi(OBTC_DEPOSIT).remove_liquidity_one_coin(_lp, 2, _lp.mul(PERCENT_MAX.sub(slippage)).div(PERCENT_MAX).div(_getLpRate()));
        uint256 _after = want.balanceOf(address(this));

        return _after.sub(_before);
    }
}