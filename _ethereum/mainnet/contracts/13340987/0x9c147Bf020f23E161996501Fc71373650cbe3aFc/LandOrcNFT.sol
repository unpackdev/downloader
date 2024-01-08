// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";

import "./LandOrc.sol";

contract LandOrcNFT is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, AccessControlUpgradeable, ERC721BurnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    address public lorcAddress;

    /// Events
    event NewLandNFTToken(uint tokenId, string tokenURI, uint256 valuation);
    event UpdateTokenURI(uint tokenId, string oldTokenURI, string newTokenURI);

    function initialize(string memory _name, string memory _symbol) initializer public {
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        // Increment to start tokenID with 1
        _tokenIdCounter.increment();
    }

    /// @dev Mint new NFT tokens
    function safeMint(address to, string memory _tokenURI, uint256 _valuation) external onlyRole(MINTER_ROLE) {
        uint256 _id = _tokenIdCounter.current();
        _safeMint(to, _id);
        _setTokenURI(_id, _tokenURI);
        LandOrc(lorcAddress).mintNFTReward(_valuation);
        emit NewLandNFTToken(_id, _tokenURI, _valuation);
        _tokenIdCounter.increment();
    }

    /// @dev Update NFT token URI
    function updateTokenURI(uint256 _tokenId, string memory _tokenURI) external onlyRole(MINTER_ROLE) {
        string memory _oldTokenURI = super.tokenURI(_tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        emit UpdateTokenURI(_tokenId, _oldTokenURI, _tokenURI);
    }

    /// @dev Pause contract
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @dev release contract
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(_tokenId);
    }

    function setLorcAddress(address _lorcAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lorcAddress = _lorcAddress;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}
