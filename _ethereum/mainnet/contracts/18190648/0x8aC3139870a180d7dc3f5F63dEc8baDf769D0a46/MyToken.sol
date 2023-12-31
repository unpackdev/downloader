// SPDX-License-Identifier: MIT
// https://dogedoge.dog	https://t.me/DogeDogeOfficialPortal
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract DogeDoge is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Doge Doge", "DODO") {
        _mint(msg.sender,  420690000000 * (10 ** decimals())); 
    }
}
