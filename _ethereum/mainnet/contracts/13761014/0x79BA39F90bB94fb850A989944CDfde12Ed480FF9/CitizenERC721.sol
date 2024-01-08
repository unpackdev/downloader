// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./ERC721PhysicalUpgradeable.sol";
import "./CitizenENSRegistrar.sol";

contract CitizenERC721 is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PhysicalUpgradeable, ERC721BurnableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant DEVICE_ROLE = keccak256("DEVICE_ROLE");
    CountersUpgradeable.Counter private _tokenIdCounter;

    // Allow the baseURI to be updated.
    string private _baseUpdateableURI;

    // Custom CITIZEN ENS registrar.
    // NOTE: Must be placed here, after inherited memory.
    CitizenENSRegistrar public _ensRegistrar;

    event UpdateBaseURI(string baseURI);

    function initialize() initializer public {
        __ERC721_init("Kong Land Citizen", "CITIZEN");
        __ERC721Enumerable_init();
        __ERC721Physical_init();
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(DEVICE_ROLE, msg.sender);

        _tokenIdCounter.increment();
    }

    // Allow minters to mint, increment counter. NOTE: it may be desirable to mint the token with device information in one shot.
    function mint(address to) public onlyRole(MINTER_ROLE) {
        require(block.timestamp > 1631714400, "Cannot mint yet.");
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    // Admin only function for setting the ENS registrar.
    function setENSRegistrarAddress(CitizenENSRegistrar ensRegistrar) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _ensRegistrar = ensRegistrar;
    }

    // Function to transfer an NFT between wallets.
    function transfer(address to, uint256 tokenId) public {
        safeTransferFrom(msg.sender, to, tokenId);
    }

    /**
     * @dev Device specific functions.
     */
    function setRegistryAddress(address registryAddress) public onlyRole(DEVICE_ROLE) {
        _setRegistryAddress(registryAddress);
    }

    function setDevice(uint256 tokenId, bytes32 publicKeyHash, bytes32 merkleRoot) public onlyRole(DEVICE_ROLE) {
        _setDevice(tokenId, publicKeyHash, merkleRoot);
    }

    /**
     * @dev Override baseURI to modify.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUpdateableURI;
    }

    function updateBaseURI(string calldata baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseUpdateableURI = baseURI;
        emit UpdateBaseURI(baseURI);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721PhysicalUpgradeable)
    {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);

        // Transfer the ENS subdomain to the new NFT owner.
        if (from != address(0) && to != address(0)) {
            _ensRegistrar.transfer(tokenId, to);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
