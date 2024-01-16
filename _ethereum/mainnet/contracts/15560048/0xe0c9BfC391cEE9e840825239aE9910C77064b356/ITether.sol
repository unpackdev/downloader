// SPDX-License-Identifier: None
pragma solidity 0.8.14;

import "./IERC165.sol";

interface ITether is IERC165 {
  function tether(uint256 tokenId) external;
}
