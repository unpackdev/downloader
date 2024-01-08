//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

import "./IUniswapV2Router02.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

// import "./console.sol";

contract AutoBuy {
  using SafeMath for uint256;

  address haremToken;

  IUniswapV2Router02 uniswapRouterV2;
  IERC20 haremLPToken;

  constructor(address _haremToken, address _uniswapRouterV2, address _haremLPToken) public{
    haremToken = _haremToken;
    uniswapRouterV2 = IUniswapV2Router02(_uniswapRouterV2);
    haremLPToken = IERC20(_haremLPToken);
  }

  function swapAndAddLiquidity(uint256 amount) public payable{
    require(msg.value == amount.mul(2), 'Message value incorrect.');
    // console.log(haremLPToken.balanceOf(address(this)));

    address[] memory path = new address[](2);
    path[0] = uniswapRouterV2.WETH();
    path[1] = haremToken; 
    uniswapRouterV2.swapExactETHForTokens.value(amount)(0, path, address(this), block.timestamp);

    // console.log(IERC20(haremToken).balanceOf(address(this)));

    IERC20(haremToken).approve(address(uniswapRouterV2), IERC20(haremToken).balanceOf(address(this)));
    uniswapRouterV2.addLiquidityETH.value(amount)(haremToken, IERC20(haremToken).balanceOf(address(this)), 0, 0, address(this), block.timestamp);

    // console.log(haremLPToken.balanceOf(address(this)));

    haremLPToken.transfer(msg.sender, IERC20(haremLPToken).balanceOf(address(this)));
    // console.log(haremLPToken.balanceOf(address(this)));
    // console.log(haremLPToken.balanceOf(msg.sender));
  }
}
