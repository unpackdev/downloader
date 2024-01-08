// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* INHERITANCE IMPORTS */

import "./ERC1967Proxy.sol";

contract XenoERC20Proxy is ERC1967Proxy {
    constructor(address logic) ERC1967Proxy(logic, "") {}
}