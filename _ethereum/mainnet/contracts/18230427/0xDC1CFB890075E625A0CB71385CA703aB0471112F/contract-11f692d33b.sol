// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Permit.sol";

contract USDT is ERC20, Ownable, ERC20Permit {
    constructor() ERC20("USDT", "USDT") ERC20Permit("USDT") {
        _mint(msg.sender, 10000000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
