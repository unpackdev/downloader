// SPDX-License-Identifier: MIT

/* 
   _____ _                   ______ _     _     
  / ____| |                 |  ____(_)   | |    
 | |    | |__   ___  ___ ___| |__   _ ___| |__  
 | |    | '_ \ / _ \/ __/ __|  __| | / __| '_ \ 
 | |____| | | |  __/\__ \__ \ |    | \__ \ | | |
  \_____|_| |_|\___||___/___/_|    |_|___/_| |_|
                             
*/

/// @title ChessFish ERC20 Token
/// @author ChessFish
/// @notice https://github.com/Chess-Fish

pragma solidity ^0.8.22;

import "./ERC20.sol";
import "./Ownable.sol";

contract ChessFish is ERC20, Ownable {
    uint constant _initial_supply = 1e6 * 1e18;

    string name_ = "ChessFish";
    string symbol_ = "CFSH";

    constructor(address _owner) ERC20(name_, symbol_) {
        _mint(_owner, _initial_supply);
        transferOwnership(_owner);
    }
}
