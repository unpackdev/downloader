// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Chuds
 * Chuds - a contract for my non-fungible creatures.
 */
contract Chuds is ERC721Tradable {
     
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("CHUDS", "CHUDS", _proxyRegistryAddress)
    {

    }

    function baseTokenURI() override public pure returns (string memory) {
        return "ipfs://QmZuGDjG5xqd6AmKMjsCStVdpUfxZp2xEtorFr3u7f6Q6P/"; 
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmRFLd9fHbTqkWuWcoHp8ACkwof5bDPZetEFoL6EZQ8RCt?filename=chuds.json";
    }

}
