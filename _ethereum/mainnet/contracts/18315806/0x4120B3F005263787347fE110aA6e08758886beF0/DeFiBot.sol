// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./Ownable.sol";
import "./ERC20.sol";

contract DeFiBot is Ownable, ERC20 {
  address private immutable _pair;

  address private _marketing;
  address private _revenue;

  event MarketingSet(address indexed previousMarketing, address indexed newMarketing);
  event RevenueSet(address indexed previousRevenue, address indexed newRevenue);

  constructor() ERC20("DeFi Bot", "DEFIBOT") {
    IUniswapV2Router02 routerContract;

    if (block.chainid == 1) { // Ethereum
      routerContract = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    } else if (block.chainid == 56) { // Binance Smart Chain
      routerContract = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    }

    _pair = IUniswapV2Factory(routerContract.factory()).createPair(address(this), routerContract.WETH());
    _mint(_msgSender(), 10 ** decimals() * 1e6); // 1M
  }

  function _transfer(address sender, address recipient, uint256 amount) internal override {
    address pair = _pair;

    if ((sender == pair || recipient == pair) && balanceOf(pair) != 0) { // buying or selling and liquidity provided
      uint256 share = amount / 50; // 2%

      if (_marketing != address(0)) {
        amount -= share;
        super._transfer(sender, _marketing, share);
      }

      if (_revenue != address(0)) {
        amount -= share;
        super._transfer(sender, _revenue, share);
      }

      if (sender == pair) { // buying
        amount -= share / 2; // keep 1% in LP
      }
    }

    super._transfer(sender, recipient, amount);
  }

  function setMarketing(address marketing) external onlyOwner {
    emit MarketingSet(_marketing, marketing);
    _marketing = marketing;
  }

  function setRevenue(address revenue) external onlyOwner {
    emit RevenueSet(_revenue, revenue);
    _revenue = revenue;
  }
}
