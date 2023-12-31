/** 
website : https://pingu.fun
telegram: https://t.me/PinguOfficialPortal
twitter : https://twitter.com/PinguERC20_

Listen up, crypto-peeps! PINGU Coin ain’t just another fish in the sea. 
Nah, this is where crypto meets claymation!
Once a little black penguin from the arctic, PINGU has now turned digital, 
and he’s bringing the party to the blockchain.
**/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract Pingu is ERC20 { 
    constructor() ERC20("Pingu", "PINGU") { 
        _mint(msg.sender, 900_000_000 * 10**18);
    }
}