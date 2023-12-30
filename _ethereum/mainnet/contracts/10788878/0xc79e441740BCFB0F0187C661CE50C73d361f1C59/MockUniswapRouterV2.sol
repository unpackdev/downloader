// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import "./GelatoActionsStandard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract MockUniswapRouterV2 {

    using SafeERC20 for IERC20;


    function getPaths(address _sellToken, address _buyToken) public pure returns(address[] memory tokenPath) {
        tokenPath = new address[](2);
        tokenPath[0] = _sellToken;
        tokenPath[1] = _buyToken;
    }

    function getAmountsIn(uint256 _buyAmount, address[] memory) public pure returns (uint[] memory expectedRates) {
        expectedRates = new uint256[](2);
        expectedRates[1] = _buyAmount * 300;
    }

}
