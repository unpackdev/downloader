// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./OKLGWithdrawable.sol";

contract HoneypotCheck is OKLGWithdrawable {
  IUniswapV2Router02 private router;

  // PancakeSwap: 0x10ED43C718714eb63d5aA57B78B54704E256024E
  // Uniswap V2: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  constructor(address _router) {
    router = IUniswapV2Router02(_router);
  }

  function buyThenSellNoSlippage(address token) external payable {
    _buyThenSell(token, 100, 100);
  }

  function buyThenSellSingleSlippage(address token, uint16 slippage)
    external
    payable
  {
    _buyThenSell(token, slippage, slippage);
  }

  function buyThenSellDualSlippage(
    address token,
    uint16 buySlippage,
    uint16 sellSlippage
  ) external payable {
    _buyThenSell(token, buySlippage, sellSlippage);
  }

  // 0 <= [buySlippage,sellSlippage] <= 100
  function _buyThenSell(
    address token,
    uint16 buySlippage,
    uint16 sellSlippage
  ) private {
    require(msg.value > 0, 'Must send ETH to buy token');
    require(buySlippage <= 100, 'slippage cannot be more than 100%');
    require(sellSlippage <= 100, 'slippage cannot be more than 100%');

    address pair = IUniswapV2Factory(router.factory()).getPair(
      router.WETH(),
      token
    );

    (uint112 _r01, uint112 _r11, ) = IUniswapV2Pair(pair).getReserves();
    uint256 amountTokensToReceiveNoSlip = 0;
    if (IUniswapV2Pair(pair).token0() == router.WETH()) {
      amountTokensToReceiveNoSlip = (msg.value * _r11) / _r01;
    } else {
      amountTokensToReceiveNoSlip = (msg.value * _r01) / _r11;
    }

    // buy
    address[] memory buyPath = new address[](2);
    buyPath[0] = router.WETH();
    buyPath[1] = token;
    router.swapExactETHForTokensSupportingFeeOnTransferTokens{
      value: msg.value
    }(
      (amountTokensToReceiveNoSlip * (100 - buySlippage)) / 100,
      buyPath,
      address(this),
      block.timestamp
    );

    // sell
    uint256 currentBalance = IERC20(token).balanceOf(address(this));
    (uint112 _r02, uint112 _r12, ) = IUniswapV2Pair(pair).getReserves();
    uint256 amountETHToReceiveNoSlip = 0;
    if (IUniswapV2Pair(pair).token0() == router.WETH()) {
      amountETHToReceiveNoSlip = (currentBalance * _r02) / _r12;
    } else {
      amountETHToReceiveNoSlip = (currentBalance * _r12) / _r02;
    }

    address[] memory sellPath = new address[](2);
    sellPath[0] = token;
    sellPath[1] = router.WETH();
    IERC20(token).approve(address(router), currentBalance);

    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      currentBalance,
      (amountETHToReceiveNoSlip * (100 - sellSlippage)) / 100,
      sellPath,
      msg.sender,
      block.timestamp
    );
  }

  function getRouter() external view returns (address) {
    return address(router);
  }

  function setRouter(address _router) external onlyOwner {
    router = IUniswapV2Router02(_router);
  }

  receive() external payable {}
}
