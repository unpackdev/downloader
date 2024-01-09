// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ReentrancyGuard.sol";
import "./SafeTransferLib.sol";
import "./IThorchainRouter.sol";

interface IUniswapRouterV2 {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to, uint deadline
    ) external payable;
}

contract TSAggregatorUniswapV2 is ReentrancyGuard {
    using SafeTransferLib for address;

    address public weth;
    IUniswapRouterV2 public swapRouter;

    constructor(address _weth, address _swapRouter) {
        weth = _weth;
        swapRouter = IUniswapRouterV2(_swapRouter);
    }

    // Needed for the swap router to be able to send back ETH
    receive() external payable {}

    function swapIn(
        address tcRouter,
        address tcVault,
        string calldata tcMemo,
        address token,
        uint amount,
        uint amountOutMin,
        uint deadline
    ) public nonReentrant {
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.safeApprove(address(swapRouter), amount);

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = weth;
        swapRouter.swapExactTokensForETH(
            amount,
            amountOutMin,
            path,
            address(this),
            deadline
        );

        uint balance = address(this).balance;
        IThorchainRouter(tcRouter).depositWithExpiry{value: balance}(
            payable(tcVault),
            address(0), // ETH
            balance,
            tcMemo,
            deadline
        );
    }

    function swapOut(address token, address to) public payable nonReentrant {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;
        swapRouter.swapExactETHForTokens{value: msg.value}(
            0, // amountOutMin FIXME
            path,
            to,
            type(uint).max // deadline
        );
    }
}

