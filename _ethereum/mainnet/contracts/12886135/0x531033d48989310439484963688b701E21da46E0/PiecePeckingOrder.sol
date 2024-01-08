// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Tradable.sol";

/**
 * @title PiecePeckingOrder
 * PiecePeckingOrder - a contract for my puzzle piece.
 */
contract PiecePeckingOrder is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("PiecePeckingOrder", "GWPPO", _proxyRegistryAddress)
    {}

    function baseTokenURI() public pure override returns (string memory) {
        return "https://www.grannywolf.com/api/pieces/pecking-order/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.grannywolf.com/api/contracts/pecking-order";
    }
}
