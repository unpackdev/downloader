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
 * @dev Earning strategy that accepts renCRV, earns CRV and converts CRV back to renCRV as yield.
 */
contract StrategyCurveRenCrv is StrategyCurveLpBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // Pool parameters
    address public constant RENCRV_GUAGE = address(0xB1F2cdeC61db658F091671F5f199635aEF202CAC); // renCrv guage
    address public constant REN_SWAP = address(0x93054188d876f558f4a66B2EF1d97d16eDf0895B); // REN swap

    constructor(address _vault) StrategyCurveLpBase(_vault, RENCRV_GUAGE, REN_SWAP) public {
    }
    
    /**
     * @dev Claims CRV from Curve and convert it back to renCRV. Only vault, governance and strategist can harvest.
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
        // Curve: WBTC --> renCRV
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