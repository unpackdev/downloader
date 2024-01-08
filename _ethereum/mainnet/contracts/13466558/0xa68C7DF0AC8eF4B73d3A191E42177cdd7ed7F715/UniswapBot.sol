// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;


import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";

contract Constant { 

    address public constant uniswapRouterV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xFbbE9b1142C699512545f47937Ee6fae0e4B0aA9;
}
contract UniswapBot is Constant, Ownable { 
    using SafeERC20 for IERC20; 
    using SafeMath for uint256;
    constructor() public { 
        IERC20(USDC).safeApprove(uniswapRouterV2, type(uint256).max);
    } 
    
    function deposit() external payable { 
        uint ethAmount = msg.value;
        address[] memory path;
        path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;
        uint256 amountOutMin = IUniswapV2Router02(uniswapRouterV2).getAmountsOut(
            ethAmount, path
        )[1];
        uint256 amountToken = IUniswapV2Router02(uniswapRouterV2).swapExactETHForTokens{
            value: ethAmount
        }(amountOutMin, path, address(this), block.timestamp + 15)[1];
        path[0] = USDC;
        path[1] = WETH;
        amountOutMin = IUniswapV2Router02(uniswapRouterV2).getAmountsOut(
            amountToken, path
        )[1];
        uint256 amountETH = IUniswapV2Router02(uniswapRouterV2).swapExactTokensForETH(amountToken, amountOutMin, path, msg.sender, block.timestamp + 15)[1];
        require(amountETH >= ethAmount.mul(90).div(100));
    }
}


