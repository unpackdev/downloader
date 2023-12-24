// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "./ERC20.sol";

contract FifthScapeToken is ERC20 {
    uint256 private INITIAL_SUPPLY = 5211000000 ether;

    constructor() ERC20("5th Scape", "5SCAPE") {
        _mint(0x2F893f7a0E15a6dF9320cf0aE7087De228482C1F, INITIAL_SUPPLY);
    }
}
