// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract AwooCoin is ERC20, Ownable {
    constructor() ERC20("AwooCoin", "ACK") {
        _mint(msg.sender, 2000000e18);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}