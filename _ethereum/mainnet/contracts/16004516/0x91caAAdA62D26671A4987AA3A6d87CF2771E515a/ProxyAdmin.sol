// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./ProxyAdmin.sol"; 

contract _ProxyAdmin is ProxyAdmin {
    constructor() ProxyAdmin() {}
}
