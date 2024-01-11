// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract Dolr is ERC20, Ownable {
    constructor() ERC20("DOLR", "DOLR") {
        _mint(msg.sender, 55000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}