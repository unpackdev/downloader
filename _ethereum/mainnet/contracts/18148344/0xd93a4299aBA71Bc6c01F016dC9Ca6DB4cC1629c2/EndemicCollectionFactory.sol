// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./AccessControlUpgradeable.sol";
import "./ClonesUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./Initializable.sol";

import "./ICollectionInitializer.sol";

contract EndemicCollectionFactory is Initializable, AccessControlUpgradeable {
    using AddressUpgradeable for address;
    using ClonesUpgradeable for address;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public implementation;
    address public collectionAdministrator;

    event NFTContractCreated(
        address indexed nftContract,
        address indexed owner,
        string name,
        string symbol,
        string category,
        uint256 royalties
    );

    event ImplementationUpdated(address indexed newImplementation);
    event CollectionAdministratorUpdated(address indexed newAdministrator);

    error CollectionAdministratorCannotBeZeroAddress();

    struct DeployParams {
        string name;
        string symbol;
        string category;
        uint256 royalties;
    }

    struct OwnedDeployParams {
        address owner;
        string name;
        string symbol;
        string category;
        uint256 royalties;
    }

    modifier onlyContract(address _implementation) {
        require(
            _implementation.isContract(),
            "EndemicCollectionFactory: Implementation is not a contract"
        );
        _;
    }

    function initialize() external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createToken(DeployParams calldata params)
        external
        onlyRole(MINTER_ROLE)
    {
        _deployContract(
            msg.sender,
            params.name,
            params.symbol,
            params.category,
            params.royalties
        );
    }

    function createTokenForOwner(OwnedDeployParams calldata params)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _deployContract(
            params.owner,
            params.name,
            params.symbol,
            params.category,
            params.royalties
        );
    }

    function updateImplementation(address newImplementation)
        external
        onlyContract(newImplementation)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        implementation = newImplementation;

        ICollectionInitializer(implementation).initialize(
            msg.sender,
            "Collection Template",
            "CT",
            1000,
            collectionAdministrator
        );

        emit ImplementationUpdated(newImplementation);
    }

    function updateCollectionAdministrator(address newCollectionAdministrator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (newCollectionAdministrator == address(0)) {
            revert CollectionAdministratorCannotBeZeroAddress();
        }

        collectionAdministrator = newCollectionAdministrator;

        emit CollectionAdministratorUpdated(newCollectionAdministrator);
    }

    function _deployContract(
        address owner,
        string memory name,
        string memory symbol,
        string memory category,
        uint256 royalties
    ) internal {
        address proxy = implementation.clone();

        ICollectionInitializer(proxy).initialize(
            owner,
            name,
            symbol,
            royalties,
            collectionAdministrator
        );

        emit NFTContractCreated(
            proxy,
            owner,
            name,
            symbol,
            category,
            royalties
        );
    }
}
