// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";

import "./TreasuryNode.sol";
import "./ERC721Market.sol";

/**
 * @title Faktura NFTs implemented using the ERC-721 standard.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
contract FakturaUpgradeable is
Initializable,
TreasuryNode,
OwnableUpgradeable,
ERC721Upgradeable,
ERC721Market,
ERC721EnumerableUpgradeable,
ERC721BurnableUpgradeable,
UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // if a token's URI has been locked or not
    mapping(uint256 => bool) public tokenURILocked;
    // Mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    // gets incremented to placehold for tokens not minted yet
    uint256 public expectedTokenSupply;
    // Counter for mint
    CountersUpgradeable.Counter private _tokenIdCounter;
    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This farms the initialize call out to inherited contracts as needed.
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint256 _tokenSupply,
        address payable _fakturaPaymentAddress,
        address payable _creatorPaymentAddress,
        uint256 _secondaryFakturaFeeBasisPoints,
        uint256 _secondaryCreatorFeeBasisPoints
    ) public initializer {
        __TreasuryNode_init(_fakturaPaymentAddress, _creatorPaymentAddress, _secondaryFakturaFeeBasisPoints, _secondaryCreatorFeeBasisPoints);
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        // set the initial expected token supply
        expectedTokenSupply = _tokenSupply;

        require(expectedTokenSupply > 0);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    // Allow the platform to update a token's URI if it's not locked yet (for fixing tokens post mint process)
    function updateTokenURI(uint256 tokenId, string calldata _tokenURI)
    external
    onlyOwner
    {
        // ensure that this token exists
        require(_exists(tokenId));
        // ensure that the URI for this token is not locked yet
        require(tokenURILocked[tokenId] == false);
        // update the token URI
        _setTokenURI(tokenId, _tokenURI);
    }

    // Locks a token's URI from being updated
    function lockTokenURI(uint256 tokenId) external onlyOwner {
        // ensure that this token exists
        require(_exists(tokenId));
        // lock this token's URI from being changed
        tokenURILocked[tokenId] = true;
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return expectedTokenSupply;
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        require(_tokenIdCounter.current() < totalSupply(), "There's no token to mint.");

        _safeMint(to, _tokenIdCounter.current());
        _setTokenURI(_tokenIdCounter.current(), uri);
        _tokenIdCounter.increment();
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev This is a no-op, just an explicit override to address compile errors due to inheritance.
     */
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Upgradeable, ERC721Market, ERC721EnumerableUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
        uint256[46] private __gap;
}