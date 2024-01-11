// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ENSReverseRegistration.sol";
import "./Multicall.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Beacon.sol";
import "./BeaconProxy.sol";
import "./RegistryOwnable.sol";
import "./P00lsTokenCreator.sol";
import "./P00lsTokenXCreator.sol";

/// @custom:security-contact security@p00ls.com
contract P00lsCreatorRegistry is
    AccessControlUpgradeable,
    ERC721Upgradeable,
    RegistryOwnableUpgradeable,
    UUPSUpgradeable,
    Multicall
{
    bytes32 public constant REGISTRY_MANAGER_ROLE = keccak256("REGISTRY_MANAGER_ROLE");
    bytes32 public constant UPGRADER_ROLE         = keccak256("UPGRADER_ROLE");

    Beacon private __beaconCreator;
    Beacon private __beaconXCreator;
    string private __baseURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor()
        initializer()
    {}

    function initialize(
        address       _admin,
        string memory _name,
        string memory _symbol
    )
        external
        initializer()
    {
        __AccessControl_init();
        __ERC721_init(_name, _symbol);
        __RegistryOwnable_init(address(this));

        _mint(_admin, addressToUint256(address(this)));
        _setupRole(REGISTRY_MANAGER_ROLE, _admin);
        _setupRole(UPGRADER_ROLE,         _admin);

        __beaconCreator  = new Beacon();
        __beaconXCreator = new Beacon();
    }

    /**
     * Creator token creation
     */
    function createToken(
        address owner,
        string calldata name,
        string calldata symbol,
        string calldata xname,
        string calldata xsymbol,
        bytes32 root
    )
        external
        onlyRole(REGISTRY_MANAGER_ROLE)
        returns (address)
    {
        address creator  = address(new BeaconProxy(__beaconCreator));
        address xCreator = address(new BeaconProxy(__beaconXCreator));

        P00lsTokenCreator(creator).initialize(
            name,
            symbol,
            root,
            xCreator
        );
        P00lsTokenXCreator(xCreator).initialize(
            xname,
            xsymbol,
            creator
        );

        _mint(owner, addressToUint256(creator));
        return creator;
    }

    /**
     * Support transferOwnership by the tokenized contracts
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        override
        returns (bool)
    {
        return addressToUint256(spender) == tokenId || super._isApprovedOrOwner(spender, tokenId);
    }

    /**
     * Default admin is overriden to use the NFT mechanism
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return role == DEFAULT_ADMIN_ROLE && owner() == account || super.hasRole(role, account);
    }

    /**
     * Token URI customization
     */
    function setBaseURI(string memory baseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        __baseURI = baseURI;
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return __baseURI;
    }

    /**
     * Beacon
     */
    function beaconCreator()
        external
        view
        returns (address)
    {
        return address(__beaconCreator);
    }

    function beaconXCreator()
        external
        view
        returns (address)
    {
        return address(__beaconXCreator);
    }

    function upgradeCreatorToken(address newImplementation)
        external
        onlyRole(UPGRADER_ROLE)
    {
        __beaconCreator.upgradeTo(newImplementation);
    }

    function upgradeXCreatorToken(address newImplementation)
        external
        onlyRole(UPGRADER_ROLE)
    {
        __beaconXCreator.upgradeTo(newImplementation);
    }

    /**
     * ENS
     */
    function setName(address ensregistry, string calldata ensname)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ENSReverseRegistration.setName(ensregistry, ensname);
    }

    /**
     * Upgradeability
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
