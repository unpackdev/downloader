// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IERC1155.sol";

abstract contract IMemeLtd is IERC1155 {
  function totalSupply(uint256 tokenId) virtual external view returns (uint256);
}
