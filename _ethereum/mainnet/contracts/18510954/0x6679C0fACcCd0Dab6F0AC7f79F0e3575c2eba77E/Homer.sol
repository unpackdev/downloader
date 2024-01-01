// SPDX-License-Identifier: MIT

//https://t.me/homer_nft

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract HOMERNFT is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("HOMERNFT", "HOMERNFT") {
        _mint(msg.sender,  1500000 * (10 ** decimals())); 
    }

}
