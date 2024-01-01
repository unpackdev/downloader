// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.20;

import "./ERC20Burnable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract FLOW is ERC20Burnable{
  IUniswapV2Router02 private uniswapV2Router;
  address private uniswapV2Pair;
  address public immutable owner;
  uint256 deployedTimestamp;
  bool unlocked;

  event Unlocked(uint256 amount);

  constructor(string memory _name, string memory _symbol, uint256 _mintAmount, uint256 _lockAmount, address _owner) ERC20(_name, _symbol){
    owner = _owner;
    deployedTimestamp = block.timestamp;
    
    _deployPair();
    _mint(msg.sender, _mintAmount);
    _mint(address(this), _lockAmount);
  }

  function unlock() public {
    require(msg.sender == owner, "Only owner can unlock");
    require(block.timestamp >= deployedTimestamp + 5 * 365 days, "Unlock only after 5 years");
    require(unlocked == false, "Already unlocked");
    unlocked = true;
    uint256 amount = balanceOf(address(this));
    _transfer(address(this), owner, amount);

    emit Unlocked(amount);
  }

  function _deployPair() internal {
    uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
  }

  function _update(address from, address to, uint256 value) internal override{
    if(from == uniswapV2Pair || to == uniswapV2Pair){
      uint256 burnAmount = value / 100;
      value -= burnAmount;
      _burn(from, burnAmount);
    }
    super._update(from, to, value);
  }

}