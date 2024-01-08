// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract BBC is ERC721Tradable {  
    
    constructor(address _proxyRegistryAddress) ERC721Tradable("NFTSquads Bully Bulls", "BBC", _proxyRegistryAddress){}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://api.nftsquads.io/asset/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.nftsquads.io/collections/";
    }
}
