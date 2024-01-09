pragma solidity =0.6.6;

import "./UniswapV2Library.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";

contract FlashLoanerSushi {
  address immutable factory;
  uint constant deadline = 1 hours;
  IUniswapV2Router02 immutable sushiRouter;

  constructor(address _factory, address _sushiRouter) public {
    factory = _factory;  
    sushiRouter = IUniswapV2Router02(_sushiRouter);
  }

  function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
      address[] memory path = new address[](2);
      uint amountTokenBorrowed = _amount0 == 0 ? _amount1 : _amount0;
      
      address token0 = IUniswapV2Pair(msg.sender).token0();
      address token1 = IUniswapV2Pair(msg.sender).token1();

      require(msg.sender == UniswapV2Library.pairFor(factory, token0, token1), "Unauthorized"); 
      require(_amount0 == 0 || _amount1 == 0);

      path[0] = _amount0 == 0 ? token1 : token0;
      path[1] = _amount0 == 0 ? token0 : token1;

      IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
      
      token.approve(address(sushiRouter), amountTokenBorrowed);

      uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountTokenBorrowed, path)[0];
      uint amountReceived = sushiRouter.swapExactTokensForTokens(amountTokenBorrowed, amountRequired, path, msg.sender, now+deadline)[1];

      IERC20 outputToken = IERC20(_amount0 == 0 ? token0 : token1);
      outputToken.transfer(tx.origin, amountReceived - amountRequired); 
  }
}