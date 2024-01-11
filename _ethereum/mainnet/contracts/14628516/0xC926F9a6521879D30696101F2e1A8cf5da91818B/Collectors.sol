// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20.sol";

contract Collectors is ERC20 {

    constructor () ERC20("Collectors", "COLL") {
        _mint(msg.sender, 100_000_000 ether);
    }

}
