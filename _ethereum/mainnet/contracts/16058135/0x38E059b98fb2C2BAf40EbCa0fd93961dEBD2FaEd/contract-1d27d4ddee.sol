// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

/// @custom:security-contact alice@scarletdeath.com
contract DeathOS is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("deathOS", "DEATHOS") {
        _mint(msg.sender, 25000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
