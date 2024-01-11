// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155.sol";

struct ProductToken {
    IERC1155 contractAddress;
    uint256[] tokenIds;
}
