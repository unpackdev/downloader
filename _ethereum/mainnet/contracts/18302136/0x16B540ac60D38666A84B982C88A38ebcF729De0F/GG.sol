// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./ERC721VotesUpgradeable.sol";
import "./Initializable.sol";

/// @custom:security-contact admin@apestdao.com
contract GenGov is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721PausableUpgradeable, AccessControlUpgradeable, EIP712Upgradeable, ERC721VotesUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin, address pauser, address minter)
        initializer public
    {
        __ERC721_init("GenGov", "GG");
        __ERC721URIStorage_init();
        __ERC721Pausable_init();
        __AccessControl_init();
        __EIP712_init("GenGov", "1");
        __ERC721Votes_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(MINTER_ROLE, minter);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "apestdao.eth";
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId, string memory uri)
        public
        onlyRole(MINTER_ROLE)
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721Upgradeable, ERC721PausableUpgradeable, ERC721VotesUpgradeable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721Upgradeable, ERC721VotesUpgradeable)
    {
        super._increaseBalance(account, value);
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
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
