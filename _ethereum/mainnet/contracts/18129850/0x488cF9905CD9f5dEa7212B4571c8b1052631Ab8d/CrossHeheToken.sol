// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OFT.sol";

/// @title Cross Hehe Token
contract CrossHeheToken is OFT {
  constructor(address _layerZeroEndpoint, uint256 _initialSupply, address _to) OFT("HEHE", "HEHE", _layerZeroEndpoint) {
    _mint(_to, _initialSupply * (10 ** decimals()));
  }
}
