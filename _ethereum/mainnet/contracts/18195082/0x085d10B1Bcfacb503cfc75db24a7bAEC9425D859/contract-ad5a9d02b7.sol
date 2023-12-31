// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract FuckJoeBiden is ERC20 {
    constructor() ERC20("FuckJoeBiden", "FKBIDEN") {
        _mint(msg.sender, 100000 * 10 ** decimals());
    }
}
