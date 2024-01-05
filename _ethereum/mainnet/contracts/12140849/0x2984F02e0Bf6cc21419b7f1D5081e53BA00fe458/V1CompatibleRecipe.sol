//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "./UniPieRecipe.sol";
import "./IWETH.sol";

contract V1CompatibleRecipe is UniPieRecipe {
    using SafeERC20 for IERC20;

    constructor(
        address _weth,
        address _uniRouter,
        address _sushiRouter,
        address _lendingRegistry,
        address _pieRegistry) UniPieRecipe(_weth, _uniRouter, _sushiRouter, _lendingRegistry, _pieRegistry) {
            //nothing here
    }

    function toPie(address _pie, uint256 _outputAmount) external payable {
        uint256 calculatedSpend = getPrice(address(WETH), _pie, _outputAmount);
        // console.log("calculated spend", calculatedSpend);

        // convert to WETH
        address(WETH).call{value: msg.value}("");
        
        // bake pie
        uint256 outputAmount = _bake(address(WETH), _pie, msg.value, _outputAmount);

        // transfer output
        IERC20(_pie).safeTransfer(_msgSender(), outputAmount);

        // if any WETH left convert it into ETH and send it back
        uint256 wethBalance = WETH.balanceOf(address(this));
        if(wethBalance != 0) {
            // console.log("returning WETH");
            // console.log(wethBalance);
            IWETH(address(WETH)).withdraw(wethBalance);
            payable(msg.sender).transfer(wethBalance);
        }
    }

    function calcToPie(address _pie, uint256 _poolAmount) external returns(uint256) {
        return getPrice(address(WETH), _pie, _poolAmount);
    }

    fallback () external payable {}
}