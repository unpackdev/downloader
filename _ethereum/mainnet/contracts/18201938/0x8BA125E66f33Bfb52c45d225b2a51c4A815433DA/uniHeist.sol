// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "IUniswapV2Router02.sol";
/** 
 * @title uniHeist
 */
contract UniHeist {
    function buy(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin) public {
      
    IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
    
    IERC20(_tokenIn).approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, _amountIn);
  
    address[] memory path = new address[](2);
    path[0] = _tokenIn;
    path[1] = _tokenIn;
    IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).swapExactTokensForTokensSupportingFeeOnTransferTokens(_amountIn, _amountOutMin, path, address(this), block.timestamp);
    }

   function sell(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin) public {
      
    //No `transferFrom` statement needed here
    //Sell only works if this line below exists
    //approve below is giving permission for UNISWAP_V2_ROUTER to spend msg.sender tokens
    //But who has the tokens to be spent is addres(this)
    //Looks like the EVM still needs `msg.sender` to be approved
    //Precisely because the transaction involves the manipulation of the token, even if it is not spent by `msg.sender`
    IERC20(_tokenIn).approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, _amountIn);
   
    address[] memory path = new address[](2);
    path[0] = _tokenIn;
    path[1] = _tokenOut;

        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).swapExactTokensForTokensSupportingFeeOnTransferTokens(_amountIn, _amountOutMin, path, msg.sender, block.timestamp);
    }
}