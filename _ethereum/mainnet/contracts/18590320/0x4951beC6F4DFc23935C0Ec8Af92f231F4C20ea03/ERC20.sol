// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC20.sol";

contract BTMToken is ERC20 {
    constructor() ERC20("Bytom DAO", "BTM") {
        _mint(msg.sender, 2100000000 * 10**8);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}