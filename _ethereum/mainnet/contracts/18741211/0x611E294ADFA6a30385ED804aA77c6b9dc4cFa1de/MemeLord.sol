pragma solidity ^0.8.0;

import "./ERC20.sol";

contract MemeLord is ERC20 {
    constructor(uint256 initialSupply) ERC20("MemeLord", "ML") {
        _mint(msg.sender, initialSupply);
    }
}