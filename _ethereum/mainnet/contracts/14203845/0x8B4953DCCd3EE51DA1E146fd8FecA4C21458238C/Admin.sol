// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "AdminBase.sol";

contract Admin is AdminBase {
    constructor(address _admin) {
        _addAdmin(_admin);
    }
}
