// SPDX-License-Identifier: MIT
// https://jakethedog.co	https://t.me/JakeOfficialPortal

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Jake is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Jake", unicode"Джейк") {
        _mint(msg.sender,  1000000000 * (10 ** decimals())); 
    }
}
