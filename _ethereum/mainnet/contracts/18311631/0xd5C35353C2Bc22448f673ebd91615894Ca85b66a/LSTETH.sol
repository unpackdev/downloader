// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./Voucher.sol";

/**
 *
 */
contract LSTETH is Voucher {
    constructor(
        string memory name_,
        string memory symbol_,
        address factory_
    ) Voucher(name_, symbol_, factory_) {}
}
