// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Tradable.sol";

/**
 * @title PieceLostAtSea
 * PieceLostAtSea - a contract for my puzzle piece.
 */
contract PieceLostAtSea is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("PieceLostAtSea", "GWPLAS", _proxyRegistryAddress)
    {}

    function baseTokenURI() public pure override returns (string memory) {
        return "https://www.grannywolf.com/api/pieces/lost-at-sea/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.grannywolf.com/api/contracts/lost-at-sea";
    }
}
