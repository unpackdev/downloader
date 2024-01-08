pragma solidity ^0.7.0;

import "./ERC20.sol";

/// @title Fake Volume Token
contract FakeVolToken is ERC20("FakeVol", "FAKEVOL") {
  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor() public {
    _mint(msg.sender, 1 ether);
  }
}