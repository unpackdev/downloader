// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Tradable.sol";

/**
 * @title HashGarageSpecials
 * HashGarageSpecials - a contract for my non-fungible cars.
 */
contract HashGarageSpecials is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("HashGarageSpecials", "HGSp", _proxyRegistryAddress)
    {}

    function baseTokenURI() public override pure returns (string memory) {
        return "https://hashgarage.com/api/metadata/specials/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://hashgarage.com/api/metadata/contract/specials";
    }

    function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }
}