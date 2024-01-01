// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract EtherQuake is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("EtherQuake", "ETHQK")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 1400000000 * 10 ** 18);
    }


function endPresale() external onlyOwner {
        // Additional logic to end the presale can be added here
        // For example, transferring ownership, burning unsold tokens, etc.
    }
}