// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract RamenToken is ERC20Burnable, Ownable {
  uint8 private _decimals = 18;

  event TokenScale(uint8 oldDecimals, uint8 newDecimals);

  constructor() ERC20("ramen.bet", "RMN") {
    _mint(msg.sender, 1000000000 ether);
  }

  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  /**
   * In case dynamic decimals are supported in the future, it would be nice to keep the token value
   * at a reasonable ratio to stablecoin pairs.
   */
  function setDecimals(uint8 newDecimals) external onlyOwner {
    require(_decimals != newDecimals, "Decimals did not change.");
    uint8 oldDecimals = _decimals;
    _decimals = newDecimals;
    emit TokenScale(oldDecimals, newDecimals);
  }
}
