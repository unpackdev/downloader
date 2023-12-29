// SPDX-License-Identifier: MIT

// VIKINGS ASSEMBLE! DEATH OR GLORY!

// www.vikingpepe.site
// t.me/VIKINGPEPEinvite
// twitter.com/Viking_pepe

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract VIKINGPEPE is ERC20, Ownable {
    constructor() ERC20("VIKING PEPE", "VPEPE") {
        _mint(msg.sender, 420690000000000 * 10 ** decimals());
    }
}
