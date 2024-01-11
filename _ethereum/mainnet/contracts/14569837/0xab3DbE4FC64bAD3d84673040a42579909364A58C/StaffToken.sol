// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract StaffToken is ERC20{
    constructor() ERC20("StaffToken", "STAFF"){
        _mint(address(0xc45420EFf330c4C850a165e79B01d9ba98d3A247), 100_000_000*10**18);
    }
}
