// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "./IERC20.sol";
import "./SafeMath.sol";

interface IWorldToken is IERC20 {
    function distribute(uint256 _actualAmount) external;
}

interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts);
}

contract WorldSwap {
    using SafeMath for uint256;

    constructor() {
        // WORLD
        IERC20(address(0xBF494F02EE3FdE1F20BEE6242bCe2d1ED0c15e47)).approve(
            address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D), // Uniswap
            ~uint256(0)
        );
    }

    function buy(uint256 amountOutMin, address recipient, uint256 deadline) external payable {
        address[] memory path = new address[](2);
        path[0] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH
        path[1] = address(0xBF494F02EE3FdE1F20BEE6242bCe2d1ED0c15e47); // WORLD

        uint256[] memory amount = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            address(this),
            deadline
        );

        IERC20(path[1]).transfer(
            recipient,
            amount[1].sub(amount[1].mul(3).div(100))
        );
    }

    function sell(uint256 amountIn, uint256 amountOutMin, address recipient, uint256 deadline) external {
        address[] memory path = new address[](2);
        path[0] = address(0xBF494F02EE3FdE1F20BEE6242bCe2d1ED0c15e47); // WORLD
        path[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH

        IERC20(path[0]).transferFrom(
            msg.sender,
            address(this),
            amountIn
        );

        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).swapExactTokensForETH(
            amountIn.sub(amountIn.mul(3).div(100)),
            amountOutMin,
            path,
            recipient,
            deadline
        );
    }

    function distributeRewards() external {
        IWorldToken world = IWorldToken(address(0xBF494F02EE3FdE1F20BEE6242bCe2d1ED0c15e47));
        uint256 balance = world.balanceOf(address(this));
        uint256 rewards = balance.div(3);
        require(rewards > 0, "Not enough rewards to distribute");

        world.distribute(rewards);
        world.transfer(address(0xD4713A489194eeE0ccaD316a0A6Ec2322290B4F9), rewards); // marketingAddress
        world.transfer(address(0x13701EdCBD3A0BD958F7548E92c41272E2AF7517), rewards); // lpStakingAddress
    }
}
