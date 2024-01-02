// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IDexRouter.sol";

contract TokenSwapHelper is ReentrancyGuard {
    IDexRouter public constant swapRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public immutable swapPair;

    IERC20 private immutable swapTokenAddress;

    address public immutable recipient;

    constructor(address _tokenAddress, address _swapPair, address _recipient) {
        swapTokenAddress = IERC20(_tokenAddress);
        swapPair = _swapPair;
        recipient = _recipient;
    }

    function swapTokenForETH(uint256 amountIn, uint256) external nonReentrant {
        require(msg.sender == address(swapTokenAddress), "TokenSwapHelper: Only the token can call this function");
        address[] memory path = new address[](2);
        path[0] = address(swapTokenAddress);
        path[1] = WETH;

        swapTokenAddress.approve(address(swapRouter), amountIn);

        // make the swap
        swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0, // accept any amount of ETH
            path,
            recipient,
            block.timestamp + 300
        );
    }
}
