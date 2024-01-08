// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IShare.sol";
import "./MapReducer.sol";

contract BankVotingShare is IShare, MapReducer {
  address constant BANK = 0x24A6A37576377F63f194Caa5F518a60f45b42921;

  constructor(address[] memory handlers_) MapReducer(handlers_) {}

  function balanceOf(address account) public view override(IShare) returns (uint256) {
    return reduce(account);
  }

  function map(address handler, address account) internal view override(MapReducer) returns (uint256) {
    return IShare(handler).balanceOf(account);
  } 

}