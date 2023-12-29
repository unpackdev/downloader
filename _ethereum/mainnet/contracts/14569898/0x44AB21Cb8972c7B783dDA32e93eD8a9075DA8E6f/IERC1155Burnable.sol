// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155.sol";

interface IERC1155Burnable is IERC1155 {
    function burn(address account, uint256 id, uint256 value) external;
}