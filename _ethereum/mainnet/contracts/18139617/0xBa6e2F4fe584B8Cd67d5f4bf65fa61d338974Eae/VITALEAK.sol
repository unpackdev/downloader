// SPDX-License-Identifier: MIT
// https://vitaleaketh.org	https://t.me/VitaleakethOfficialPortal	https://twitter.com/Vitaleaketh
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract VITALEAK is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Vitaleak.eth", "VITALEAK") {
        _mint(msg.sender,  1000000000 * (10 ** decimals())); 
    }

}
