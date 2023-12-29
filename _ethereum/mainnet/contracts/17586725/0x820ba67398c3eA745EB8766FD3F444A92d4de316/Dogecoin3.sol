// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Dogecoin3 is Ownable, ERC20Burnable {
  address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  address public immutable router;
  address public immutable pair;

  constructor() ERC20("Dogecoin 3.0", "DOGE3.0") {
    router = ROUTER;
    IUniswapV2Router02 routerContract = IUniswapV2Router02(ROUTER);
    pair = IUniswapV2Factory(routerContract.factory()).createPair(address(this), routerContract.WETH());
    _mint(_sender, 1e9 * 10 ** decimals()); // 1B
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
    require(to == _sender || to == pair || owner() == address(0), "Dogecoin3::_beforeTokenTransfer: not launched");
    super._beforeTokenTransfer(from, to, amount);
  }
}
