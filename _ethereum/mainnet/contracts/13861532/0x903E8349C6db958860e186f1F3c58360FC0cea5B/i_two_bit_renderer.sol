// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
pragma abicoder v2;

import "./two_bit.sol";

interface ITwoBitRenderer {
  function tokenURI(uint256 tokenId, TwoBit memory tb) external view returns (string memory);
}