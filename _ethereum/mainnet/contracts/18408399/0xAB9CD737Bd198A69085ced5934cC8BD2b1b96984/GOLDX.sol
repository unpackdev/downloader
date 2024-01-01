// SPDX-License-Identifier: MIT
/*


██████   ██████   ██      ██████  ██   ██ 
██       ██    ██ ██      ██   ██  ██ ██  
██   ███ ██    ██ ██      ██   ██   ███   
██    ██ ██    ██ ██      ██   ██  ██ ██  
 ██████   ██████  ███████ ██████  ██   ██        

                


*/


pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./Ownable.sol";

/// @custom:security-contact infosec@goldx.com
contract GOLDX is ERC20, ERC20Permit, Ownable {
    constructor(address initialOwner)
        ERC20("GOLDX", "GOLDX")
        ERC20Permit("GOLDX")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 200000000 * 10 ** decimals());
    }
}