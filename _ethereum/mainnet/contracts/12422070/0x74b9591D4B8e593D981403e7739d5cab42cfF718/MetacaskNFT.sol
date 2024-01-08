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

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Mapping from token ID to originator's commission address
    mapping(uint256 => address) private _commissionAddresses;
    mapping(uint256 => uint256) private _commissionRates;

    /**
     * Emitted when `owner` adds `commissionAddress` to `tokenId` token.
     */
    event SetCommission(address indexed owner, address indexed commissionAddress, uint256 indexed tokenId);

    constructor() ERC721("MetacaskNFT", "MCK") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
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

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
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
    function getCommissionAddress(uint256 tokenId) public view virtual returns (address) {
        require(_exists(tokenId), "MetacaskNFT: commission address query for nonexistent token");

        return _commissionAddresses[tokenId];
    }

    /**
     * @dev get address for originator commission
     */
    function getCommissionRate(uint256 tokenId) public view virtual returns (uint256) {
        require(_exists(tokenId), "MetacaskNFT: commission address query for nonexistent token");

        return _commissionRates[tokenId];
    }

    /**
     * @dev set address for originator commission
     *
     * Emits an {SetCommission} event.
     */
    function _setCommission(uint256 tokenId, address commissionAddress, uint256 commissionRate) internal virtual {
        _commissionAddresses[tokenId] = commissionAddress;
        _commissionRates[tokenId] = commissionRate;
        emit SetCommission(ERC721.ownerOf(tokenId), commissionAddress, tokenId);
    }

    /**
     * @dev mint Item for metacask NFT
     */
    function mintItem(address to, string memory myTokenURI, address commissionAddress, uint256 commissionRate)
        public
        onlyWhiteListed(to)
        returns (uint256)
    {
        require(hasRole(MINTER_ROLE, msg.sender));
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(to, id);
        _setTokenURI(id, myTokenURI);
        _setCommission(id, commissionAddress, commissionRate);

        return id;
    }
}
