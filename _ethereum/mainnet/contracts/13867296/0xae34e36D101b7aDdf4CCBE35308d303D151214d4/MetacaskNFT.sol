// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./WhiteList.sol";

contract MetacaskNFT is ERC721, ERC721URIStorage, Pausable, AccessControl, WhiteList {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Commission {
        address receiver;
        uint amount;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Mapping from token ID to originator's commission address
    mapping(uint256 => Commission[]) _commissions;

    // base labs uri
    string private _baseLabsURI;

    // collection contractName
    string public _contractName;

    // collection level metadata uri
    string public _metadataURI;

    /**
     * Emitted when `owner` adds `commissions` to `tokenId` token.
     */
    event SetCommission(address indexed owner, uint256 indexed tokenId, Commission[] commissions);

    constructor(string memory name, string memory symbol, string memory contractName, string memory metadataURI) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _baseLabsURI = "https://ipfs.io/ipfs/";
        _contractName = contractName;
        _metadataURI = metadataURI;
        // Whitelist the burn address by default
        super.addToWhiteList(0x000000000000000000000000000000000000dEaD);
    }

    /// @dev Add an account to the minter role. Restricted to admin.
    function addMinter(address account) public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        grantRole(MINTER_ROLE, account);
    }

    /// @dev Remove an account from the minter role. Restricted to admin.
    function removeMinter(address account) public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        revokeRole(MINTER_ROLE, account);
    }

    function pause() public {
        require(hasRole(PAUSER_ROLE, msg.sender));
        _pause();
    }

    function unpause() public {
        require(hasRole(PAUSER_ROLE, msg.sender));
        _unpause();
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseLabsURI;
    }

    function setBaseLabsURI(string memory uri) public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _baseLabsURI = uri;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    onlyWhiteListed(to)
    override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId)
    internal
    onlyWhiteListed(to)
    override
    {
        super._transfer(from, to, tokenId);
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

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev get address for originator commission
     */
    function _getCommission(uint256 tokenId) public view virtual returns (Commission[] memory) {
        require(_exists(tokenId), "MetacaskNFT: commission address query for nonexistent token");

        return _commissions[tokenId];
    }

    /**
     * @dev set address for originator commission
     *
     * Emits an {SetCommission} event.
     */
    function _setCommission(uint256 tokenId, Commission[] memory commissions) internal virtual {
        for (uint i = 0; i < commissions.length; i++) {
            _commissions[tokenId].push(commissions[i]);
        }
        emit SetCommission(ERC721.ownerOf(tokenId), tokenId, commissions);
    }

    /**
     * @dev mint Item for metacask NFT
     */
    function mintItem(address to, string memory myTokenURI, Commission[] memory commissions)
    public
    onlyWhiteListed(to)
    returns (uint256)
    {
        require(hasRole(MINTER_ROLE, msg.sender));
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(to, id);
        _setTokenURI(id, myTokenURI);
        _setCommission(id, commissions);

        return id;
    }
}
