// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.5.16;

import "./ERC20Detailed.sol";
import "./ERC20Mintable.sol";
import "./ERC20Pausable.sol";

contract TestERC20 is ERC20Detailed, ERC20Mintable, ERC20Pausable {
    constructor(uint amount) ERC20Detailed('CoolToken', 'COOL-DATE', 18) public {
        mint(msg.sender, amount);
    }

}