// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract NotOnlyPrayForUkraine is ERC721Tradable {

    constructor(address _proxyRegistryAddress) ERC721Tradable("Not Only Pray for Ukraine", "NOPFU", _proxyRegistryAddress) {}

    function baseTokenURI() override public pure returns (string memory) {
        return "ipfs://bafybeicuzqfj7flbg5ryu3ojie3tuljl2neuuilbtoda4biuuaftmd2poi/";
    }
}
