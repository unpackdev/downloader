// SPDX-License-Identifier: Unlicensed

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";

import "./ISushiswapRouter.sol";

contract MockSushiswapRouter {
    using SafeMath for uint256;

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address,
        uint256
    ) external returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);

        // Assume 100/1 swap rate
        uint256 exchangeRate = 100;
        address inToken = path[0];
        uint256 amountOut = amountIn.div(exchangeRate);
        require(amountOut >= amountOutMin, "amountOutMin invariant failed");

        IERC20(inToken).transferFrom(msg.sender, address(this), amountIn);
        (bool success, ) = msg.sender.call{ value: amountOut }(new bytes(0));
        require(success, "Error transfer amountOut");

        amounts[0] = amountIn;
        amounts[1] = amountOut;

        return amounts;
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address,
        uint256
    ) external payable returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);

        // Assume 100/1 swap rate
        uint256 exchangeRate = 100;
        address outToken = path[1];
        uint256 amountOut = msg.value.mul(exchangeRate);
        require(amountOut >= amountOutMin, "amountOutMin invariant failed");

        IERC20(outToken).transfer(msg.sender, amountOut);

        amounts[0] = msg.value;
        amounts[1] = amountOut;

        return amounts;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address,
        uint256
    ) external returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);

        // Assume 100/1 swap rate
        uint256 exchangeRate = 20;
        address inToken = path[0];
        // path[1] is WETH
        address outToken = path[2];
        uint256 amountOut = amountIn.mul(exchangeRate);
        require(amountOut >= amountOutMin, "amountOutMin invariant failed");

        IERC20(inToken).transferFrom(msg.sender, address(this), amountIn);
        IERC20(outToken).transfer(msg.sender, amountOut);

        amounts[0] = amountIn;
        amounts[1] = amountOut;

        return amounts;
    }

    receive() external payable {}
}
