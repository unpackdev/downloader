// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract N8C is ERC721Tradable {  
    
    constructor(address _proxyRegistryAddress) ERC721Tradable("N8F", "N8C", _proxyRegistryAddress){}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://api.nf8ball.com/assets/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.nf8ball.com/collections/";
    }
}
