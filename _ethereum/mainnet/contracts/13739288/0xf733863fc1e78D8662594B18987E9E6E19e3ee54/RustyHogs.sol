// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title RustyHogs
 * RustyHogs - a contract for non-fungible Rusty Hogs.
 */
contract RustyHogs is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("RustyHogs", "RSH", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://nft.rustyhogs.io/api/token/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://nft.rustyhogs.io/contract/rustyhogs";
    }
}
