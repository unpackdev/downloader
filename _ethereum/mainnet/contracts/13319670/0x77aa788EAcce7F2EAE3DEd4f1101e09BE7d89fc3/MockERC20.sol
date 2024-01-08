// SPDX-License-Identifier: Unlicensed

pragma solidity 0.6.12;

import "./ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_) public ERC20(name_, symbol_) {
        _mint(msg.sender, 10000000e18);
    }
}
