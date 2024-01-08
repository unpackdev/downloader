// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20Burnable.sol";

contract LORB is ERC20Burnable{
    constructor() ERC20("Leviathan Lobster Token", "LORB") {
        _mint(msg.sender, 1000000000000000000000000000000000);
    }
}