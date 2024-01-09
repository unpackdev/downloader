// SPDX-License-Identifier: UNLICENSED

// Copyright (c) WildCredit - All rights reserved
// https://twitter.com/WildCredit

pragma solidity >0.7.0;

contract ERC721Receivable {

  function onERC721Received(
    address _operator,
    address _user,
    uint _tokenId,
    bytes memory _data
  ) public returns (bytes4) {
    return 0x150b7a02;
  }
}
