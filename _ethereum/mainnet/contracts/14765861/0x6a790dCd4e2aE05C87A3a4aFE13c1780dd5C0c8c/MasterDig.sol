// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./IERC2981.sol";

contract MasterDig is ERC721, IERC2981, ERC721URIStorage, Ownable {
    // 01 (artistId) 01 (artworkId) 0001 (productId)
    uint256 public constant ARTWORK_ID_OFFSET = 10000;
    uint256 public constant ARTIST_ID_OFFSET  = 100 * ARTWORK_ID_OFFSET;

    mapping(uint256 => uint96) private _royaltyBasisPoints;

    constructor() ERC721("MasterDig", "Dig") {}

    function safeMint(
        address to, uint96 artistId, uint96 artworkId, uint96 productId,
        string memory uri, uint96 royaltyBasisPoint
    )
        public
        onlyOwner
    {
        require (artworkId < 100 && productId < 10000, "tokenId format verification failed");
        require (royaltyBasisPoint <= 10000, "royaltyBasisPoint <= 10000");

        uint256 tokenId = artistId * ARTIST_ID_OFFSET
                        + artworkId * ARTWORK_ID_OFFSET
                        + productId;
        _royaltyBasisPoints[tokenId] = royaltyBasisPoint;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        uint96 basisPoint = _royaltyBasisPoints[tokenId];
        return (owner(), (salePrice * basisPoint) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}