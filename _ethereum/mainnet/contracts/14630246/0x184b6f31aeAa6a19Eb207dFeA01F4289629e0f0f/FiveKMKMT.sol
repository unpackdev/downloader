// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";

contract FiveKMKMT is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    constructor() ERC20("FiveKM KMT", "KMT") ERC20Permit("FiveKM KMT") {
        _mint(msg.sender, 50000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
