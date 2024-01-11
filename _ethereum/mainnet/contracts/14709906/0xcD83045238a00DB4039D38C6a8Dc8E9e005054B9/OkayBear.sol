// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/// @title: OkayBear
/// @author: okaybear.com

import "./ERC721Mini.sol";

contract OkayBear is ERC721Mini {
    constructor() ERC721Mini("OkayBear", "OKB") {}
}
