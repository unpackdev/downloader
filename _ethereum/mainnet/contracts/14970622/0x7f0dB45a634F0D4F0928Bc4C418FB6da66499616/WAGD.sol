//SPDX-License-Identifier: MIT

/*
 __      __  _____    ________________   
/  \    /  \/  _  \  /  _____/\______ \  
\   \/\/   /  /_\  \/   \  ___ |    |  \ 
 \        /    |    \    \_\  \|    `   \
  \__/\  /\____|__  /\______  /_______  /
       \/         \/        \/        \/ 
*/

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Royalty.sol";
import "./Counters.sol";

contract WAGD is ERC721, ERC721Enumerable, ERC721Royalty {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 constant TOTAL_SUPPLY = 100;

    constructor() ERC721("WAGD", "WAGD") {
        _setDefaultRoyalty(0x6D31541dE738A1Df6cB2B21255d4d46D41cE361B, 500);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeih2tpm6wleeue6a4afchccs52lz5hjeldoznb747wmldctyio5xpq/";
    }

    function mint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();

        require(tokenId <= TOTAL_SUPPLY, "Minted out");

        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
        super._resetTokenRoyalty(tokenId);
    }
}
