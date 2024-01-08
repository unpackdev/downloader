// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Tradable.sol";

/**
 * @title PieceCastleBrush
 * PieceCastleBrush - a contract for my puzzle piece.
 */
contract PieceCastleBrush is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("PieceCastleBrush", "GWPCB", _proxyRegistryAddress)
    {}

    function baseTokenURI() public pure override returns (string memory) {
        return "https://www.grannywolf.com/api/pieces/castle-brush/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.grannywolf.com/api/contracts/castle-brush";
    }
}
