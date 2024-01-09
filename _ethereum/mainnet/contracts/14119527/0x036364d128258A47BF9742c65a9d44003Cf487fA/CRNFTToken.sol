// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721RoyaltyUpgradeable.sol";
contract CRNFTToken is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, ERC721BurnableUpgradeable, ERC721RoyaltyUpgradeable, AccessControlUpgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    CountersUpgradeable.Counter private _tokenIdCounter;

    // Mapping from token ID to the creator's address.
    mapping(uint256 => address) private tokenCreators;
    // Mapping from token ID to the creator's address.
    mapping(uint256 => address) private tokenCurators;

    // Event indicating metadata was updated.
    event TokenURIUpdated(uint256 indexed _tokenId, string  _uri);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC721_init("CRNFT", "CRN");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __AccessControl_init();
        __Ownable_init();
        __ERC721Royalty_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev Checks that the token was created by the sender.
     * @param _tokenId uint256 ID of the token.
     */
    modifier onlyTokenCreator(uint256 _tokenId) {
        address creator = tokenCreator(_tokenId);
        require(creator == msg.sender, "must be the creator of the token");
        _;
    }

    /**
     * @dev Checks that the token is owned by the sender.
     * @param _tokenId uint256 ID of the token.
     */
    modifier onlyTokenOwner(uint256 _tokenId) {
        address owner = ownerOf(_tokenId);
        require(owner == msg.sender, "must be the owner of the token");
        _;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.moralis.io:2053/ipfs/";
    }

    function safeMint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _setTokenCreator(tokenId, to);
        _setTokenCurator(tokenId, msg.sender);
        _setTokenRoyalty(tokenId, to, 750);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable, ERC721RoyaltyUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
    * @dev Gets the creator of the token.
    * @param _tokenId uint256 ID of the token.
    * @return address of the creator.
    */
    function tokenCreator(uint256 _tokenId) public view returns (address) {
        return tokenCreators[_tokenId];
    }

    /**
    * @dev Gets the curator of the token.
    * @param _tokenId uint256 ID of the token.
    * @return address of the creator.
    */
    function tokenCurator(uint256 _tokenId) public view returns (address) {
        return tokenCurators[_tokenId];
    }

    /**
     * @dev Internal function for setting the token's creator.
     * @param _tokenId uint256 id of the token.
     * @param _creator address of the creator of the token.
     */
    function _setTokenCreator(uint256 _tokenId, address _creator) internal {
        tokenCreators[_tokenId] = _creator;
    }

    /**
     * @dev Internal function for setting the token's creator.
     * @param _tokenId uint256 id of the token.
     * @param _curator address of the curator of the token.
     */
    function _setTokenCurator(uint256 _tokenId, address _curator) internal {
        tokenCurators[_tokenId] = _curator;
    }

    /**
     * @dev Updates the token metadata if the owner is also the
     *      creator.
     * @param _tokenId uint256 ID of the token.
     * @param _uri string metadata URI.
     */
    function updateTokenMetadata(uint256 _tokenId, string memory _uri)
    public
    onlyTokenOwner(_tokenId)
    onlyTokenCreator(_tokenId)
    {
        _setTokenURI(_tokenId, _uri);
        emit TokenURIUpdated(_tokenId, _uri);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address recipient,
        uint96 fraction
    ) public {
        _setTokenRoyalty(tokenId, recipient, fraction);
    }

    function setDefaultRoyalty(address recipient, uint96 fraction) public {
        _setDefaultRoyalty(recipient, fraction);
    }

    function deleteDefaultRoyalty() public {
        _deleteDefaultRoyalty();
    }
}
