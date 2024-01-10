// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./IERC1155.sol";

interface IIYKYKERC1155 is IERC1155 {
  function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
}
