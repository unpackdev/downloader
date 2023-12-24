// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract FTF is ERC20, ERC20Burnable {
    address private minter;

    constructor(
        uint256 initialSupply,
        address admin
    ) ERC20("For The Future", "FTF") {
        _mint(msg.sender, initialSupply * (10 ** 18));
        minter = admin;
    }

    //add supply
    function addSupply(address receiver, uint amount) public {
        require(msg.sender == minter);
        _mint(receiver, amount * (10 ** 18));
    }
}
