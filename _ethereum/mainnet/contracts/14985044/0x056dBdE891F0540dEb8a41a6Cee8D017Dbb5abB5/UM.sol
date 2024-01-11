/*
 █     █░ ██▓  ██████      ▒██   ██▒▓██   ██▓▒███████▒
▓█░ █ ░█░▓██▒▒██    ▒      ▒▒ █ █ ▒░ ▒██  ██▒▒ ▒ ▒ ▄▀░
▒█░ █ ░█ ▒██▒░ ▓██▄        ░░  █   ░  ▒██ ██░░ ▒ ▄▀▒░ 
░█░ █ ░█ ░██░  ▒   ██▒      ░ █ █ ▒   ░ ▐██▓░  ▄▀▒   ░
░░██▒██▓ ░██░▒██████▒▒ ██▓ ▒██▒ ▒██▒  ░ ██▒▓░▒███████▒
░ ▓░▒ ▒  ░▓  ▒ ▒▓▒ ▒ ░ ▒▓▒ ▒▒ ░ ░▓ ░   ██▒▒▒ ░▒▒ ▓░▒░▒
  ▒ ░ ░   ▒ ░░ ░▒  ░ ░ ░▒  ░░   ░▒ ░ ▓██ ░▒░ ░░▒ ▒ ░ ▒
  ░   ░   ▒ ░░  ░  ░   ░    ░    ░   ▒ ▒ ░░  ░ ░ ░ ░ ░
    ░     ░        ░    ░   ░    ░   ░ ░       ░ ░    
                        ░            ░ ░     ░        
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title: United Metaverse
/// @author: wis.xyz

import "./ERC721Mini.sol";

contract UM is ERC721Mini {
    constructor() ERC721Mini("United Metaverse", "UM") {}
}
