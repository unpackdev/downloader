// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BubbleGumJuice.sol";

contract BubbleGumGame is BubbleGumJuice {
  constructor(string memory _name, string memory _symbol, uint _launchAt) BubbleGumJuice(_name, _symbol, _launchAt) {}
}