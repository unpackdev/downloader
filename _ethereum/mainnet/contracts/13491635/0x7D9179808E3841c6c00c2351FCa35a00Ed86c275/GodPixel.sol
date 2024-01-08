// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenUriBase.sol";

contract GodPixel is TokenUriBase {
  constructor (
    string memory name_,
    string memory symbol_,
    address openseaProxyRegistryAddress_,
    address payable royaltyAddress_,
    uint256 royaltyBps_
  ) TokenUriBase(name_, symbol_, openseaProxyRegistryAddress_, royaltyAddress_, royaltyBps_) {
    
  }
}
