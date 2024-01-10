// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract TestToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Test Token", "TEST") {
        _mint(msg.sender, 2000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
