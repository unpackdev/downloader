// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract DaiwoToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("DAIWO Token", "DAIWO") {
        _mint(msg.sender, initialSupply);
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }
}
