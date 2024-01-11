// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract EJRToken is ERC20, Ownable {
    constructor() ERC20("EJR Token", "EJR") {
        _mint(msg.sender, 125 * (10 ** 18));
    }

    function increaseTotalSupply() public onlyOwner {
        _mint(msg.sender, 125 * (10 ** 18));
    }
}