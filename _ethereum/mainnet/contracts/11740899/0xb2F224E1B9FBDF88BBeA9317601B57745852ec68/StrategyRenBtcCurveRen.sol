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
 * @dev Strategy for renBTC on Curve's Ren pool.
 * Important tokens:
 * - want: renBTC
 * - lp: renCrv
 * - lpVault: renCrvv
 */
contract StrategyRenBtcCurveRen is StrategyCurveBase {
    
    // Pool parameters
    address public constant RENCRV_VAULT = address(0x59aAbBC33311fD0961F17E684584c0A090034d5F); // renCrv vault
    address public constant REN_SWAP = address(0x93054188d876f558f4a66B2EF1d97d16eDf0895B); // REN swap

    /**
     * @dev Initializes the strategy.
     */
    function initialize(address _vault) public initializer {
        __StrategyCurveBase__init(_vault, RENCRV_VAULT, REN_SWAP);
    }

    /**
     * @dev Deposits the want token into Curve in exchange for lp token.
     * @param _want Amount of want token to deposit.
     * @param _minAmount Minimum LP token to receive.
     */
    function _depositToCurve(uint256 _want, uint256 _minAmount) internal override {
        ICurveFi(curve).add_liquidity([_want, 0], _minAmount);
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