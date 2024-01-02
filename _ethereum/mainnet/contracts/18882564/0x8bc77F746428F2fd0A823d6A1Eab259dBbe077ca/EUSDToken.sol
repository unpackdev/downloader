// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract EUSDToken is ERC20, ERC20Burnable, Ownable {
    uint256 constant initialSupply = 20_000_000 * (10**18);

    constructor(address initialOwner) ERC20("EUSD Token", "EUSD") Ownable(initialOwner) {
        _mint(msg.sender, initialSupply);
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(_msgSender(), amount);
    }
}