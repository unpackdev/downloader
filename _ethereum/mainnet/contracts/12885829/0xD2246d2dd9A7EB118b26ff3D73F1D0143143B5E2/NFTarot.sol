// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Tradable.sol";

/**
 * @title NFTarot
 * NFTarot - a contract for my non-fungible creatures.
 */
contract NFTarot is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("NFTarot", "GWNFT", _proxyRegistryAddress)
    {}

    function baseTokenURI() public pure override returns (string memory) {
        return "https://www.grannywolf.com/api/nftarots/cards/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.grannywolf.com/api/contracts/nftarot";
    }
}
