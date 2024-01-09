// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Strings.sol";
import "./SlimeProducer.sol";

/*
     ▄█▀▀▀█▄█       ██             ██▄▄       ▄▄██ 
    ▄██    ▀█       ██             ██▀▀▄▄   ▄▄▀▀██ 
    ▀███▄           ██             ██  ▀▀█ █▀▀  ██ 
     ▀█████▄        ██             ██    ███    ██
    ▄     ▀██       ██             ██     ▀     ██
    ██     ██       ██             ██           ██  
    █▀█████▀        ██▄▄▄▄▄▄██     ██           ██  
    
    Slime / 2022 / V1.0
*/

contract Slime is SlimeProducer {
    using Strings for uint256;
    uint256 constant MAX_SUPPLY=6666;

    constructor() SlimeProducer("Slime", "SLM") {}

    function maxSupply() external pure override returns (uint256) {
         return MAX_SUPPLY;
    }
}
