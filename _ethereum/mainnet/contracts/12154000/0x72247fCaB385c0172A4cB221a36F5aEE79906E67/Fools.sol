//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract FoolsToken is ERC20 {

  mapping (uint256 => address) lastFewTraders;
  uint256 public currentTrader = 0;
  uint256 public traderCount = 0;
  uint256 public MAX_TRADERS = 10;

  constructor() ERC20("FoolsToken", "FOOLS") {
      _mint(msg.sender, 420000 ether);
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
    uint256 number = uint(uint160(address(block.coinbase))) + block.timestamp;

    bool shouldWarp = number % 10 >= 9;
    uint256 warpAmount = 0;
    if(shouldWarp) {
      address warpTo = getLastTrader();
      warpAmount = amount / 10;
      super._transfer(sender, warpTo, warpAmount);
    }

    amount = amount - warpAmount;

    super._transfer(sender, recipient, amount);

    addToTraders(sender);
  }

  function addToTraders(address trader) private {
    lastFewTraders[traderCount] = trader;

    traderCount++;

    if(traderCount >= MAX_TRADERS) {
      traderCount = 0;
    }
  }

  function getLastTrader() private returns (address trader) {
    currentTrader++;
    if(currentTrader >= MAX_TRADERS){
      currentTrader = 0;
    } 

    return lastFewTraders[currentTrader];
  }
}
