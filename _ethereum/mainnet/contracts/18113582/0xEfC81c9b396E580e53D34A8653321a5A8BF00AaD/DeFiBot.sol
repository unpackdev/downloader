// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./Ownable.sol";
import "./ERC20.sol";

contract DeFiBot is Ownable, ERC20 {
  address private immutable _pair;
  address private immutable _marketing;

  address private _revenue;

  constructor() ERC20("DeFi Bot", "DEFIBOT") {
    IUniswapV2Router02 routerContract;

    if (block.chainid == 1) { // Ethereum
      routerContract = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    } else if (block.chainid == 56) { // Binance Smart Chain
      routerContract = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    }

    _pair = IUniswapV2Factory(routerContract.factory()).createPair(address(this), routerContract.WETH());
    address marketing = _msgSender();
    _marketing = marketing;
    _mint(marketing, 10 ** decimals() * 1e6); // 1M
  }

  function _transfer(address sender, address recipient, uint256 amount) internal override {
    address pair = _pair;

    if ((sender == pair || recipient == pair) && balanceOf(pair) != 0) { // buying or selling and liquidity provided
      uint256 fee = amount / 20; // 5%
      amount -= fee;
      uint256 share = fee * 2 / 5;
      super._transfer(sender, _marketing, share);

      if (_revenue != address(0)) { // if not set more tokens stay in LP
        super._transfer(sender, _revenue, share);
      }
    }

    super._transfer(sender, recipient, amount);
  }

  function setRevenue(address revenue) external onlyOwner {
    _revenue = revenue;
  }
}
