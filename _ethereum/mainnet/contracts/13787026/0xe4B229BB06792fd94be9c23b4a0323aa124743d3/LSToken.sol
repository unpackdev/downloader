//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract LSToken is ERC20 {
    uint constant _initial_supply = 100 * (10**18);
    constructor() ERC20("LSToken", "LS") public {
        _mint(msg.sender, _initial_supply);
    }
}
