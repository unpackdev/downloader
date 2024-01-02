// SPDX-License-Identifier: MIT

/*
    telegram: https://t.me/+AVGycvnRX2I1MTEx
*/

pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract CthulhuCoin is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("Cthulhu Coin", "Cthulhu") Ownable (msg.sender) {
        _mint(msg.sender, initialSupply * 1e18);
    }

}