// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// https://debittorrent.com	

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract DBT is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("DBT", "DBT") {
        _mint(msg.sender,  100000000000 * (10 ** decimals())); 
    }

}
