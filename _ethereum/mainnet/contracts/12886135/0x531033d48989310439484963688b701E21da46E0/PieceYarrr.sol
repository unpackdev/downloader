// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Tradable.sol";

/**
 * @title PieceYarrr
 * PieceYarrr - a contract for my puzzle piece.
 */
contract PieceYarrr is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("PieceYarrr", "GWPY", _proxyRegistryAddress)
    {}

    function baseTokenURI() public pure override returns (string memory) {
        return "https://www.grannywolf.com/api/pieces/yarrr/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.grannywolf.com/api/contracts/yarrr";
    }
}
