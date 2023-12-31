// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./ERC20.sol";

contract gem is ERC20 {
    constructor() ERC20("gem", "g") {
        uint256 supply = 420_000_000_000;
        _mint(msg.sender, supply * 10**18);
    }
}