// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Counters.sol";

contract ArtworkCollection is
    Context,
    Ownable,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    Counters.Counter private _tokenIdTracker;

    string private _creatorProfileURI;
    string private _creator;
    
    string private _baseTokenURI;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => string) private _websiteURIs;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory creatorName,
        string memory creatorURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _creator = creatorName;
        _creatorProfileURI = creatorURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATOR_ROLE, _msgSender());
    }
    
    /**
     * Returns the URI of this collection creator's profile
     */
    function creatorProfileURI() public view virtual returns (string memory) {
        return _creatorProfileURI;
    }
    
    /**
     * Set the URI of this collection creator's profile
     */
    function setCreatorProfileURI(string memory _uri) public virtual {
        _creatorProfileURI = _uri;
    }
    
    /**
     * Returns the identity of this collection's creator
     */
    function creator() public view virtual returns (string memory) {
        return _creator;
    }

    function baseURI() public view virtual returns (string memory) {
        return _baseURI();
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Mint NFT token with tokenURI
     * See {ERC721-_mint}.
     *
     * Requirements:
     * - the caller must have the `CREATOR_ROLE`.
     */
    function mint(address to, string memory _tokenURI) public virtual {
        require(hasRole(CREATOR_ROLE, _msgSender()), "ArtworkCollection: must have creator role to mint");

        // Mint
        _mint(to, _tokenIdTracker.current());
        // Add URI to tokenId
        _tokenURIs[_tokenIdTracker.current()] = _tokenURI;
        // Increment the counter
        _tokenIdTracker.increment();
    }
    
    /**
     * Mint NFT token with tokenURI
     * See {ERC721-_mint}.
     *
     * Requirements:
     * - the caller must have the `CREATOR_ROLE`.
     */
    function mint(address to, string memory _tokenURI, string memory _websiteURI) public virtual {
        require(hasRole(CREATOR_ROLE, _msgSender()), "ArtworkCollection: must have creator role to mint");

        // Mint
        _mint(to, _tokenIdTracker.current());
        // Add URI to tokenId
        _tokenURIs[_tokenIdTracker.current()] = _tokenURI;
        // Add website URI to tokenId
        _websiteURIs[_tokenIdTracker.current()] = _websiteURI;
        // Increment the counter
        _tokenIdTracker.increment();
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ArtworkCollection: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }


    /**
     * Set website URI of the `tokenId`
     * 
     * Website URI can be used to show the details of `tokenId`
     */
    function setWebsiteURI(uint256 tokenId, string memory _websiteURI) public virtual {
        require(_exists(tokenId), "ArtworkCollection: URI set of nonexistent token");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ArtworkCollection: caller is not owner nor approved");
        _websiteURIs[tokenId] = _websiteURI;
    }
    
    /**
     * Get the website URI of the `tokenId`
     * 
     * Website URI can be used to show the details of `tokenId`
     */
    function tokenWebsiteURI(uint256 tokenId) public view virtual returns (string memory) {
        string memory _websiteURI = _websiteURIs[tokenId];
        return _websiteURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ArtworkCollection: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
