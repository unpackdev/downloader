// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./console.sol";


contract CryptoKangaroo is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("CryptoKangaroo", "CryptoKangaroo", _proxyRegistryAddress)
    {
        console.log(_proxyRegistryAddress);
    }

    function baseTokenURI() override public pure returns (string memory) {
        return "https://ipfs.io/ipfs/bafybeib2yislp2cdamp3mzvx7itmhf5jbces3zhyotrp7zlzsfmpgb23im/kangaroo/";
    }

    // function contractURI() public pure returns (string memory) {
    //     return "https://creatures-api.opensea.io/contract/opensea-creatures";
    // }
}
