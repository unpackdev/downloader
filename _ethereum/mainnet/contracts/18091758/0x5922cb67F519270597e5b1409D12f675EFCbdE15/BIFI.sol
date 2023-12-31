// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract BIFI is ERC20 {

    constructor() ERC20("Moo Test", "mooTest")  {
        _mint(msg.sender, 80_000 ether);
    }

}