// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";


contract NFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public currentTokenId;

    constructor() ERC721("AI-MARKETPLACE22", "AI-MP22") {
    }
    function contractURI() public pure returns (string memory) {
        return "https://bafkreib5j3jo2ggsk3ag3ls5fvxazjpvbez22vrmrj7bcmg6gg6u4nc4km.ipfs.nftstorage.link/";
    }

    function mintTo(address recipient, string memory tokenURI) public onlyOwner returns (uint256) {
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);
        return newItemId;
    }
}
