// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Volare is ERC20Burnable, Ownable {
    constructor(
        address owner_,
        uint256 initSupply_
    ) ERC20("Volare", "VOLR") {
        _mint(owner_, initSupply_);
        transferOwnership(owner_);
    }

    function mint(address account_, uint256 amount_) public onlyOwner {
        _mint(account_, amount_);
    }
}