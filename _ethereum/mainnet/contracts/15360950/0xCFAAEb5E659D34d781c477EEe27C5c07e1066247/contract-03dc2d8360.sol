// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20FlashMint.sol";

contract HNAG is ERC20, Ownable, ERC20Permit, ERC20FlashMint {
    constructor() ERC20("HNA G", "HNA") ERC20Permit("HNA G") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
