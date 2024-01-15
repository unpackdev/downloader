// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract Hello is ERC721URIStorage, Ownable {

    uint test = 0;
    
    constructor(uint init) ERC721('Hello', 'HELLO'){
        test = init;
    }


}