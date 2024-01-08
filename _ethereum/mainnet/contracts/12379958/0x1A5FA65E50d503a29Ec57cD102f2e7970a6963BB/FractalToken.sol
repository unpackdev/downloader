// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./ERC20.sol";

/// @title An ERC20 to simulate the real FCL token for testing purposes
/// @author Miguel Palhas <miguel@subvisual.co>
contract FractalToken is ERC20 {
  constructor(address targetOwner) ERC20("Fractal Protocol Token", "FCL") {
    _mint(targetOwner, 465000000000000000000000000);
  }
}

contract LPToken is ERC20 {
  constructor(address targetOwner) ERC20("FCL-ETH-LP Token", "FCL-ETH-LP") {
    _mint(targetOwner, 465000000000000000000000000);
  }
}
