// SPDX-License-Identifier: MIT

/*

The official Pepe x Ledger collab community coin.

0% tax, LP burnt and contract renounced.

Telegram: https://t.me/PepeLedger
X: https://x.com/PeleERC
Website: https://PepeLedger.com


██████  ███████ ██      ███████ 
██   ██ ██      ██      ██      
██████  █████   ██      █████   
██      ██      ██      ██      
██      ███████ ███████ ███████ 


*/

pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";

/// @custom:security-contact pepeledger@gmail.com
contract PepeLedger is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("Pepe Ledger", "PELE") ERC20Permit("Pepe Ledger") {
        _mint(msg.sender, 69000000000 * 10 ** decimals());
    }
}
