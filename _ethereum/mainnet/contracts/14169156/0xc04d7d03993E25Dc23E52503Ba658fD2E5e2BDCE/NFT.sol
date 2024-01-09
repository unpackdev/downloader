// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./ERC721.sol";


import "./ERC721Common.sol";

// To read more about NFTs, checkout the ERC721 standard:
// https://eips.ethereum.org/EIPS/eip-721 


/**
 * @title NFT
 * SimpleNFT - A concrete NFT contract implementation that can optionally inherit from several Mixins for added functionality or directly from ERC721Common for a barebones implementation. 
 */
contract MichaelDeployedContract is ERC721Common {    
    using Counters for Counters.Counter;

    Counters.Counter private _nextTokenId;

    /**
     * @dev Replace with your own unique name and symbol
     */
    constructor()
        ERC721Common("MichaelDeployedContract", "MCD") {
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();
    }

    function mint(address _to) public virtual returns (uint256) {
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(_to, currentTokenId);
        return currentTokenId;
    }

    function baseTokenURI() public override pure returns (string memory) {
      return "https://creatures-api.opensea.io/api/creature/";
    }
}