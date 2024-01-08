// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: X by Pak
/// @author: manifold.xyz

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Strings.sol";

import "./IX.sol";

contract X is ERC721, Ownable, ReentrancyGuard, IX {

    using Strings for uint256;

    uint256 private _mintCount;
    string private _defaultURI;
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("X", "X") {
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IX).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IX-mint}
     */
    function mint(address to) external virtual override onlyOwner nonReentrant {
        _mintCount++;
        _safeMint(to,_mintCount); 
    }

    /**
     * @dev See {IX-mint}
     */
    function mint(address to, string calldata uri) external virtual override onlyOwner nonReentrant {
        _mintCount++;
        _safeMint(to,_mintCount); 
        _tokenURIs[_mintCount] = uri;
    }

    /**
     * @dev See {IX-batchMint}
     */
    function batchMint(address to, uint16 count) external virtual override onlyOwner nonReentrant {
        for (uint16 i = 0; i < count; i++) {
            _mintCount++;
            _safeMint(to,_mintCount); 
        }
    }

    /**
     * @dev See {IX-batchMint}
     */
    function batchMint(address to, string[] calldata uris) external virtual override onlyOwner nonReentrant {
        for (uint i = 0; i < uris.length; i++) {
            _mintCount++;
            _safeMint(to,_mintCount); 
            _tokenURIs[_mintCount] = uris[i];
        }
    }
    /**
     * @dev See {IX-setBaseURI}
     */
    function setDefaultURI(string calldata uri) external virtual override onlyOwner {
        _defaultURI = uri;
    }


    /**
     * @dev See {IX-setTokenURIs}
     */
    function setTokenURIs(uint256[] calldata tokenIds, string[] calldata uris) external override onlyOwner {
        require(tokenIds.length == uris.length, "IX: Bad input");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(_exists(tokenIds[i]), "Nonexistent token");
            _tokenURIs[tokenIds[i]] = uris[i];
        }
    }

    /**
     * @dev See {IX-setTokenURI}
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external override onlyOwner {
        require(_exists(tokenId), "Nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        if (bytes(_tokenURIs[tokenId]).length == 0) {
            return string(abi.encodePacked(_defaultURI, tokenId.toString()));
        }
        return _tokenURIs[tokenId];
    }
}
