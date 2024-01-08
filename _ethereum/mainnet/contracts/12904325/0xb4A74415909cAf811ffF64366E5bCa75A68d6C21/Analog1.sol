// contracts/Analog1.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Analog is ERC20Burnable, Ownable {

    constructor(uint256 initialSupply) ERC20("Analog", "ANLOG") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint amount) external onlyOwner {
        _mint(to, amount);
    }
}