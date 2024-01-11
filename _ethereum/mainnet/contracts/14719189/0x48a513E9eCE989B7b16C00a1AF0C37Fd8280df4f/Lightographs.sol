// SPDX-License-Identifier: MIT

/**
*   @title Lightographs
*   @notice 1 of 1 lightograph art from Jeremy Cowart
*   @author Transient Labs
*/

/**
  _      _       _     _                              _         
 | |    (_)     | |   | |                            | |        
 | |     _  __ _| |__ | |_ ___   __ _ _ __ __ _ _ __ | |__  ___ 
 | |    | |/ _` | '_ \| __/ _ \ / _` | '__/ _` | '_ \| '_ \/ __|
 | |____| | (_| | | | | || (_) | (_| | | | (_| | |_) | | | \__ \
 |______|_|\__, |_| |_|\__\___/ \__, |_|  \__,_| .__/|_| |_|___/
            __/ |                __/ |         | |              
           |___/                |___/          |_|                                               
   ___                            __  ___         ______                  _          __    __        __     
  / _ \___ _    _____ _______ ___/ / / _ )__ __  /_  __/______ ____  ___ (_)__ ___  / /_  / /  ___ _/ /  ___
 / ___/ _ \ |/|/ / -_) __/ -_) _  / / _  / // /   / / / __/ _ `/ _ \(_-</ / -_) _ \/ __/ / /__/ _ `/ _ \(_-<
/_/   \___/__,__/\__/_/  \__/\_,_/ /____/\_, /   /_/ /_/  \_,_/_//_/___/_/\__/_//_/\__/ /____/\_,_/_.__/___/
                                        /___/                                                               
*/

pragma solidity ^0.8.0;

import "ERC721TLCreator.sol";

contract Lightographs is ERC721TLCreator {

    constructor(address royaltyRecp, uint256 roayltyPerc, address admin) 
    ERC721TLCreator("Lightographs", "LIGHT", royaltyRecp, royaltyPerc, admin) {}
}