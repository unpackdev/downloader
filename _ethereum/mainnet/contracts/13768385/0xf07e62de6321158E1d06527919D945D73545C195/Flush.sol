// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Flush is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Flush", "FLUSH") {
        _mint(msg.sender, 5_000_000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function setApprovedSender(address sender, bool approved) external onlyOwner {
        _setApprovedSender(sender, approved);
    }
}