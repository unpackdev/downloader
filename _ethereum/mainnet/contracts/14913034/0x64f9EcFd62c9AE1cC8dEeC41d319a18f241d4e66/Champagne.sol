// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./draft-ERC721Votes.sol";
import "./Counters.sol";

contract ChampagneCollective is ERC721, Ownable, EIP712, ERC721Votes {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Champagne Collective", "CHAMP") EIP712("Champagne Collective", "1") {
        _tokenIdCounter.increment();
        // mint the first 10
        _initialMint();
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://raw.githubusercontent.com/d3l33t/champagne/main/nft/";
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _initialMint() private onlyOwner {
        safeMint(msg.sender);
        safeMint(msg.sender);
        safeMint(msg.sender);
        safeMint(msg.sender);
        safeMint(msg.sender);
        safeMint(msg.sender);
        safeMint(msg.sender);
        safeMint(msg.sender);
        safeMint(msg.sender);
        safeMint(msg.sender);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Votes)
    {
        super._afterTokenTransfer(from, to, tokenId);
    }
}
