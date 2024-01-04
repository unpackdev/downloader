// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./Ownable.sol";
import "./IUniswapV2Router02.sol";

// import "./IUniswapV2Router02.sol";
// Tread https://uniswap.org/docs/v2/smart-contract-integration/trading-from-a-smart-contract/
// https://soliditydeveloper.com/uniswap2

contract UniMfContract is Ownable  {

  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  IUniswapV2Router02 public uniswapRouter;

  modifier ensure(uint deadline) {
    require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
    _;
  }

  constructor() public {
    uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
  }

  // Вернуть осавшиеся ETH и вызвать функцию может только владелец
  function refundLeftoverEth()
  external
  onlyOwner
  {
    msg.sender.call.value(address(this).balance)("");
  }

  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline, uint val)
  ensure(deadline)
  external
  returns (uint[] memory amounts)
  {
    amounts = uniswapRouter.swapETHForExactTokens.value(val)(amountOut, path, to, deadline);
  }

  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline, uint val)
  ensure(deadline)
  external
  returns (uint[] memory amounts)
  {
    amounts = uniswapRouter.swapExactETHForTokens.value(val)(amountOutMin, path, to, deadline);
  }

  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
  ensure(deadline)
  external
  returns (uint[] memory amounts)
  {
    amounts = uniswapRouter.swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
  }

  // important to receive ETH
  receive() payable external {}
}
