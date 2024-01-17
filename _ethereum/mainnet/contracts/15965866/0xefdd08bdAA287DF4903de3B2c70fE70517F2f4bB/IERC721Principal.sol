
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";

interface IERC721Principal is IERC721Enumerable, IERC721Metadata {
  function owner() external view returns (address);
}
