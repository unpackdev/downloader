// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract BDP is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Baby Duck Pond", "BDP", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://www.slackerduckpond.com/baby/api/assets/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.slackerduckpond.com/baby/api/collection";
    }
}