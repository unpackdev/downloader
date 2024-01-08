// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract Spiro is ERC721Tradable {

    uint8 private MAX_IN_SERIES = 22; 

    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Spiro", "OSC", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://spiro-nft-rinkeby.herokuapp.com/api/token/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://github.com/Jerboa-app/spiro-nft";
    }

    function nTokens() public view returns (uint8) { return MAX_IN_SERIES; }
}
