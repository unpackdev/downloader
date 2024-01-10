// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Zombit is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Zombit", "ZMBT") {
        _mint(msg.sender, 6000000000000 * 10**decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
