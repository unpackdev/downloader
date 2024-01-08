// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract Osuvox is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Osuvox", "VOX", _proxyRegistryAddress)
    {}

    function baseTokenURI() public pure override returns (string memory) {
        return "https://api.osuvox.io/v2/avatars/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.osuvox.io/v2/contract";
    }
}
