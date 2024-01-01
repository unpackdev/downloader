// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.7 < 0.9.0;

/*
  _______                   ____  _____  
 |__   __|                 |___ \|  __ \ 
    | | ___  __ _ _ __ ___   __) | |  | |
    | |/ _ \/ _` | '_ ` _ \ |__ <| |  | |
    | |  __/ (_| | | | | | |___) | |__| |
    |_|\___|\__,_|_| |_| |_|____/|_____/ 

    https://team3d.io
    https://discord.gg/team3d
    UniswapV3 swapper

    @author Team3d.R&D
*/

import "./UniRouterDataV3.sol";


contract UniswapV3Integration {

    address immutable public Weth9;
    uint24 public constant poolFee = 10000;

  ISwapRouter immutable uniswapV3Router;

  constructor(){
    ISwapRouter _uniswapV3Router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);//UniswapV3 router good onMainnet, Goerli, Arbitrum, Optimism, Polygon, change for others
    uniswapV3Router = _uniswapV3Router;
    Weth9 = _uniswapV3Router.WETH9();

  }

  /**
   * @dev function to buy primary token and send to the contract
   */

  function _buyTokenETH(address token, uint256 amount, uint256 amountOut, address to)internal{

    ISwapRouter.ExactInputSingleParams memory params =
        ISwapRouter.ExactInputSingleParams({
            tokenIn: Weth9,
            tokenOut: token,
            fee: poolFee,
            recipient: to,
            deadline: block.timestamp,
            amountIn: amount, //amount going to buy tokens
            amountOutMinimum: amountOut,
            sqrtPriceLimitX96: 0
        });

        // Executes the swap.
    uniswapV3Router.exactInputSingle{value: amount}(params);
  }

  function buyTokenETH(address token, uint256 amountOut)public payable{
      _buyTokenETH(token, msg.value, amountOut,msg.sender);
  }

  function buyTokenWithPathEth(address[] memory tokens, uint24[] memory fees, uint256 amountOut)public payable{
      bytes memory _path = _buildPath(tokens, fees);
    _buyTokenWithPathEth(_path, msg.value, amountOut, msg.sender);
  }

    function _buildPath(address[] memory tokens, uint24[] memory fees) internal pure returns(bytes memory){

      require(tokens.length == fees.length+1, "Path and fees do not match");
      bytes memory _path; 
      for(uint i = 0; i < tokens.length;){
        if(i== fees.length){
          _path = abi.encodePacked(_path, tokens[i]);
        }else{
          _path = abi.encodePacked(_path, tokens[i], fees[i]);
        }
        unchecked {i++;}
      }
      return _path;
    }

    function _buyTokenWithPathEth(bytes memory _path, uint256 amount, uint256 amountOut, address to)internal{

      ISwapRouter.ExactInputParams memory params =  
      ISwapRouter.ExactInputParams({
        path: _path,
        recipient:to,
        deadline: block.timestamp,
        amountIn: amount,
        amountOutMinimum:amountOut
      });

      uniswapV3Router.exactInput{value:amount}(params);

    }

}