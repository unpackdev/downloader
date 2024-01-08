// SPDX-License-Identifier: MIT
pragma solidity ^0.5.5;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Pausable.sol";
import "./ERC20Mintable.sol";


contract StakeToken is ERC20, ERC20Detailed, ERC20Pausable, ERC20Mintable {
    constructor(uint256 initialSupply) ERC20Detailed("Guarded Ether", "GETH", 18) public {
        _mint(msg.sender, initialSupply);
    }
}
