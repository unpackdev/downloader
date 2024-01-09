// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";

contract MetaFansTicket is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ADMIN_ROLE = keccak256("MINTER_ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    string baseURI;

    CountersUpgradeable.Counter private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _initialOwner,
        address _initialAdministrator,
        string memory baseURI_
    ) initializer public {
        __ERC721_init("MetaFans Ticket", "MFT");
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _initialOwner);
        _grantRole(PAUSER_ROLE, _initialAdministrator);
        _grantRole(UPGRADER_ROLE, _initialAdministrator);
        _grantRole(MINTER_ADMIN_ROLE, _initialAdministrator);
        _setRoleAdmin(MINTER_ROLE, MINTER_ADMIN_ROLE);
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function appointAdministrator(address admin) public returns (bool) {
        grantRole(PAUSER_ROLE, admin);
        grantRole(UPGRADER_ROLE, admin);
        grantRole(MINTER_ADMIN_ROLE, admin);
        return true;
    }

    function demoteAdministrator(address admin) public returns (bool) {
        revokeRole(PAUSER_ROLE, admin);
        revokeRole(UPGRADER_ROLE, admin);
        revokeRole(MINTER_ADMIN_ROLE, admin);
        return true;
    }

    function appointMinter(address minter) public returns (bool) {
        grantRole(MINTER_ROLE, minter);
        return true;
    }

    function demoteMinter(address minter) public returns (bool) {
        revokeRole(MINTER_ROLE, minter);
        return true;
    }

    function safeMint(address to, string memory uri)
        public
        onlyRole(MINTER_ROLE) whenNotPaused
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
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
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}