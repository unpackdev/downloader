// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract NFTSWTFGenesis is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    string private _tokenURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory tokenURI_
    ) ERC721(name_, symbol_) {
        _tokenURI = tokenURI_;
    }

    /**
     * @dev Safely mint a new token. The new token will get the next incremental uint value as its tokenID.
     * @param to The address that will own the minted token
     */
    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(tokenId < totalSupply(), "Non-existing token ID");

        return _tokenURI;
    }

    /**
     * Returns the total supply of tokens.
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }
}
