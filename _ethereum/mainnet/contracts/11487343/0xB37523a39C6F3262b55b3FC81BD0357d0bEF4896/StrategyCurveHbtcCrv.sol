// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./StrategyCurveLpBase.sol";
import "./ICurveFi.sol";
import "./ICurveMinter.sol";
import "./IUniswapRouter.sol";

/**
 * @dev Earning strategy that accepts hbtcCRV, earns CRV and converts CRV back to hbtcCRV as yield.
 */
contract StrategyCurveHbtcCrv is StrategyCurveLpBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // Pool parameters
    address public constant HBTCCRV_GUAGE = address(0x4c18E409Dc8619bFb6a1cB56D114C3f592E0aE79); // hbtcCrv guage
    address public constant HBTC_SWAP = address(0x4CA9b3063Ec5866A4B82E437059D2C43d1be596F); // HBTC swap

    constructor(address _vault) StrategyCurveLpBase(_vault, HBTCCRV_GUAGE, HBTC_SWAP) public {
    }
    
    /**
     * @dev Claims CRV from Curve and convert it back to hbtcCRV. Only vault, governance and strategist can harvest.
     */
    function harvest() public override {
        require(msg.sender == vault || msg.sender == governance() || msg.sender == strategist(), "not vault");
        // Claims CRV from Curve
        ICurveMinter(mintr).mint(guage);
        uint256 _crv = IERC20Upgradeable(crv).balanceOf(address(this));

        // Uniswap: CRV --> WETH --> WBTC
        if (_crv > 0) {
            IERC20Upgradeable(crv).safeApprove(uniswap, 0);
            IERC20Upgradeable(crv).safeApprove(uniswap, _crv);

            address[] memory path = new address[](3);
            path[0] = crv;
            path[1] = weth;
            path[2] = wbtc;

            IUniswapRouter(uniswap).swapExactTokensForTokens(_crv, uint256(0), path, address(this), now.add(1800));
        }
        // Curve: WBTC --> hbtcCRV
        uint256 _wbtc = IERC20Upgradeable(wbtc).balanceOf(address(this));
        if (_wbtc > 0) {
            IERC20Upgradeable(wbtc).safeApprove(curve, 0);
            IERC20Upgradeable(wbtc).safeApprove(curve, _wbtc);
            ICurveFi(curve).add_liquidity([0, _wbtc], 0);
        }
        IERC20Upgradeable want = IERC20Upgradeable(token());
        uint256 _want = want.balanceOf(address(this));
        if (_want == 0) {
            return;
        }
        uint256 _feeAmount = 0;
        if (performanceFee > 0) {
            _feeAmount = _want.mul(performanceFee).div(FEE_MAX);
            want.safeTransfer(IController(controller()).treasury(), _feeAmount);
        }
        deposit();

        emit Harvested(address(want), _want, _feeAmount);
    }
}