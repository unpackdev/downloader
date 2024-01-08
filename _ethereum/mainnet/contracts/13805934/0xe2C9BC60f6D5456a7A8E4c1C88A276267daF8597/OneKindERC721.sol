// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./IOneKindERC721.sol";

// @title 1Kind NFT (ERC721) contract
contract OneKindERC721 is
    ERC721Enumerable,
    ERC721Burnable,
    AccessControl,
    IOneKindERC721
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // counter for tracking current token id
    Counters.Counter private _tokenIdTracker;

    // base token uri for serving nft metadata
    string private _baseTokenURI;

    // access _roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");

    // @dev Constructor method for ERC721, _exchangeContractAddress is granted MINTER and URI_MANAGER ROLES
    // @param name The token name
    // @param symbol The token symbol
    // @param baseTokenURI The token baseTokenURI
    // @param _exchangeContractAddress The address of the exchange contract allowed to mint
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address _exchangeContractAddress
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        // Set Default Roles for deployer
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(URI_MANAGER_ROLE, msg.sender);
        
        // Set Default Roles for 1kind.com exchange
        _setupRole(MINTER_ROLE,  _exchangeContractAddress);
        _setupRole(URI_MANAGER_ROLE,  _exchangeContractAddress);
    }

    // @dev Mint method limited to MINTER_ROLE
    // @param to The token receiver
    function mint(address to)
        public
        virtual
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        _tokenIdTracker.increment();
        _safeMint(to, _tokenIdTracker.current());
        return _tokenIdTracker.current();
    }

    // @dev _baseURI getter method
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // @dev _baseURI setter method limited to URI_MANAGER_ROLE
    // @param permanentBaseURI The new baseTokenURI
    function setBaseURI(string memory permanentBaseURI)
        public
        virtual
        onlyRole(URI_MANAGER_ROLE)
    {
        _baseTokenURI = permanentBaseURI;
    }


    // @dev _tokenURIs setter for a tokenId. Checks token exists limited to URI_MANAGER_ROLE
    // @param tokenId The id of the token to update
    // @param permanentTokenURI The new tokenURI for this tokenId
    function setTokenURI(uint256 tokenId, string memory permanentTokenURI)
        public
        virtual
        onlyRole(URI_MANAGER_ROLE)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = permanentTokenURI;
    }

    // @dev _tokenURIs getter for a tokenId. Checks token exists
    // @param tokenId The id of the token
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return super.tokenURI(tokenId);
    }

    // @dev burns a tokenId
    // @param tokenId The id of the token
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    // @dev override for _beforeTokenTransfer
    // @param from The token sender
    // @param to The token receiver
    // @param tokenId The id of the token
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // @dev override for supportsInterface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, AccessControl, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
