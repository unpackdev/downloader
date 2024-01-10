// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

/** 
    This collection contains the various awards presented by the global competition platform MetaJam. 
    MetaJam is dedicated to the construction and innovation of the metaverse. 
*/
contract MetaJam_Awards is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter internal collectionId;

    constructor()
        ERC721("MetaJam Awards", "MetaJam")
    {}

    /** ========== mian functions ========== */
    function grant(address receiver, string memory _tokenURI) external onlyOwner {
        require(receiver != address(0), "grant: invalid address");

        uint256 mintId = collectionId.current();

        // mint token
        _mint(receiver, mintId);

        // update tokenid status
        _setTokenURI(mintId, _tokenURI);
        collectionId.increment();

        emit grantToken(mintId, receiver);
    }

    /** ========== view functions ========== */
    function totalSupply() public view returns (uint256) {
        return collectionId.current();
    }

    /** ========== event ========== */
    event grantToken(uint256 indexed tokenId, address receiver);
}


