// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Letters
 * Letters - a contract for a group of 3 non-fungible letters.
 */
contract Letters is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Letter Letter Letter", "LLL", _proxyRegistryAddress)
    {}

    function baseTokenURI() public pure override returns (string memory) {
        return "https://letterletterletter.com/api/letters/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://letterletterletter.com/api/contract";
    }
}
