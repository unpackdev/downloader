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
 * @dev Strategy for WBTC on Curve's HBTC pool.
 * Important tokens:
 * - want: WBTC
 * - lp: hbtcCrv
 * - lpVault: hbtcCrvv
 */
contract StrategyWbtcCurveHbtc is StrategyCurveBase {
    
    // Pool parameters
    address public constant HBTCCRV_VAULT = address(0x68A8aaf01892107E635d5DE1564b0D0a3FE39406); // hbtcCrv vault
    address public constant HBTC_SWAP = address(0x4CA9b3063Ec5866A4B82E437059D2C43d1be596F); // HBTC swap

    /**
     * @dev Initializes the strategy.
     */
    function initialize(address _vault) public initializer {
        __StrategyCurveBase__init(_vault, HBTCCRV_VAULT, HBTC_SWAP);
    }

    /**
     * @dev Deposits the want token into Curve in exchange for lp token.
     * @param _want Amount of want token to deposit.
     * @param _minAmount Minimum LP token to receive.
     */
    function _depositToCurve(uint256 _want, uint256 _minAmount) internal override {
        ICurveFi(curve).add_liquidity([0, _want], _minAmount);
    }

    /**
     * @dev Withdraws the want token from Curve by burning lp token.
     * @param _lp Amount of LP token to burn.
     * @param _minAmount Minimum want token to receive.
     */
    function _withdrawFromCurve(uint256 _lp, uint256 _minAmount) internal override {
        ICurveFi(curve).remove_liquidity_one_coin(_lp, 1, _minAmount);
    }
}