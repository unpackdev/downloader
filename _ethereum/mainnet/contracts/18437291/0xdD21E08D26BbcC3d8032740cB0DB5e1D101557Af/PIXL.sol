// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";

contract PIXL is ERC20Burnable {

    constructor() ERC20("Posers Games", "PIXL") {
        _mint(msg.sender, 16_000_000 ether);
    }

}
