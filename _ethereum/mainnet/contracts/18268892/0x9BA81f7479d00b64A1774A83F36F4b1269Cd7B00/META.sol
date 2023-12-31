// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC20.sol";

contract META is ERC20 {

    string constant public metaName = "META";
    string constant public metaSymbol = "$META";

    constructor(address to) ERC20(metaName, metaSymbol) { _mint(to, 10000000000e18); }
}