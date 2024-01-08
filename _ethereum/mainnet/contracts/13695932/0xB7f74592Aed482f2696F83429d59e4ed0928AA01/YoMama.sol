// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Tradable.sol";

/**
 * @title Yo mama
 *
 * Yo mama so dumb, she couldn't find anyone better to develop this contract!
 *
 *                                                   — Anonymous Motherfucker
 */
contract YoMama is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable('Yo mama', unicode'喲媽媽', _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "ipfs://QmR9CJ46mq2wGaGiniLvNcxqs8DHLm4u7MD7VibVGmWBGu/";
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmZuyiazSPwVGruyD3h8kehXNYEo6gjeEAoUvfdHEvG9Uj";
    }

    function mint(address _to, uint256 _tokenId) public onlyOwner {
        _mint(_to, _tokenId);
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }
}
