// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./ERC721.sol";
import "./IMetadataResolver.sol";

//   _____ _____ _____
//  |   | |     |_   _|
//  | | | |  |  | | |
//  |_|___|_____|_|_|_ _____ ____
//  |   __|     |  |  |   | |    \
//  |   __|  |  |  |  | | | |  |  |
//  |__|  |_____|_____|_|___|____/
//
//  @creator: Pak
//  @author: NFT Studios | Powered by Buildtree

contract NotFound is ERC721 {
    address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address constant NULL_ADDRESS = 0x0000000000000000000000000000000000000000;

    address public owner;
    IMetadataResolver public metadataResolver;

    constructor() ERC721("Not Found", "404") {
        _safeMint(msg.sender, 404);

        owner = msg.sender;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return metadataResolver.getTokenURI(_tokenId);
    }

    function setMetadataResolver(address _metadataResolver) external {
        require(msg.sender == owner, "404");

        metadataResolver = IMetadataResolver(_metadataResolver);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        if (to == DEAD_ADDRESS || to == NULL_ADDRESS) {
            _burn(tokenId);

            return;
        }

        ERC721._transfer(from, to, tokenId);
    }
}
