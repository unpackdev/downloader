// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

/**
 *           █████             ╨████████▀              ▌██████▌┌──└▌█████               █████
 *          ▐▀█████              ╫█████                  █████       ╙████▌            ▄▀█████
 *          ▀ █████▌             ╟████                   █████        █████            ⌐ █████▄
 *         ▌   █████             ╟████                   █████        █████           ▌   █████
 *        ╫     █████            ╟████                   █████       ▄████           ▌     █████
 *       ╓─     ▀█████           ╟████                   █████╥╥╥╥╥▄███             ▐      ▓█████
 *       ▌       █████▄          ╟████                   █████       ─█████         ▀       █████▄
 *      ▓         █████          ╟████                   █████         █████       ▓         █████
 *     ▄           █████         ╟████            ▓▌     █████         █████▌     ╫          └█████
 *    ╓▌           ██████        ╟████            █▌     █████         █████▀    ╓▀           ██████
 *   ╓█             █████▄       ╟████          ███▌     █████         █████    ▄█             █████▄
 * ,█████▌         ,███████     ▄██████▄     ,█████▌    ███████      █████╨   ,█████▌         ,███████
 * └└└└└└└└       └└└└└└└└└└   └└└└└└└└└└┌─┌└└└└└└└    └└└└└└└└└└──└└─        └└└└└└└─       └└└└└└└└└└
 */

import "./ECDSA.sol";
import "./SignatureChecker.sol";
import "./EnumerableSet.sol";
import "./Initializable.sol";
import {AccessControlEnumerableUpgradeable} from
    "openzeppelin-contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./Clones.sol";

import "./Collection.sol";
import "./IAlbaDelegate.sol";
import "./Types.sol";

contract CollectionFactory is Initializable, AccessControlEnumerableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SignatureChecker for EnumerableSet.AddressSet;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /// @notice Signature signers for collection deployment.
    /// @dev Removing signers invalidates the corresponding signatures.
    EnumerableSet.AddressSet private deploySigners;

    bool public isEnabled;
    mapping(bytes16 => address) public uuidToCollection;
    address internal albaDelegate;
    address internal contractManager;
    address public collectionImpl;

    error InvalidSignature();
    error CollectionAlreadyExists();
    error FactoryNotEnabled();

    event DeploymentCreated(address, bytes16);
    event ProtocolChanged(string eventName, bytes data);

    function initialize(address _albaDelegate, address _collectionImpl, address _contractManager) public initializer {
        __AccessControlEnumerable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, _contractManager);

        albaDelegate = _albaDelegate;
        collectionImpl = _collectionImpl;
        contractManager = _contractManager;
        isEnabled = true;
    }

    /**
     * @notice Deploys a new collection contract.
     * @param config The collection configuration.
     * @param saleConfig The sale configuration.
     * @param artists The artist addresses.
     * @param signature The signature gratned from the Alba backend.
     */
    function createCollection(
        CollectionConfig calldata config,
        SaleConfig calldata saleConfig,
        PaymentConfig calldata paymentConfig,
        address[] calldata artists,
        bytes calldata signature
    ) public {
        if (!isEnabled) {
            revert FactoryNotEnabled();
        }

        // Ensure the collection does not already exist.
        address existing = uuidToCollection[config.uuid];
        if (existing != address(0)) {
            revert CollectionAlreadyExists();
        }

        // Ensure the signature is valid.
        validateSignature(msg.sender, config.uuid, paymentConfig, signature);

        Collection collection = Collection(Clones.clone(collectionImpl));
        collection.initialize(IAlbaDelegate(albaDelegate), config, saleConfig, paymentConfig, contractManager, artists);

        uuidToCollection[config.uuid] = address(collection);
        emit DeploymentCreated(address(collection), config.uuid);
    }

    function validateSignature(address user, bytes16 uuid, PaymentConfig calldata conf, bytes calldata signature)
        internal
        view
    {
        bytes32 message = ECDSA.toEthSignedMessageHash(keccak256(_packData(user, uuid, conf)));
        deploySigners.requireValidSignature(message, signature);
    }

    /**
     * @notice Packs the data for signing.
     * @dev We pack separately and concat because abi.encode produces a 'stack too deep' error with so many
     * parameters. As we're encoding packed, a binary concat should be equal to encoding in one go.
     */
    function _packData(address user, bytes16 uuid, PaymentConfig calldata conf) internal view returns (bytes memory) {
        bytes memory first = abi.encode(user, uuid, block.chainid);
        bytes memory second = abi.encode(
            conf.primaryPayees, conf.primaryShareBasisPoints, conf.secondaryPayees, conf.secondaryShareBasisPoints
        );
        return bytes.concat(first, second);
    }

    /**
     * @notice Removes and adds addresses to the set of allowed signers.
     * @dev Removal is performed before addition.
     */
    function changeDeploySigners(address[] calldata delSigners, address[] calldata addSigners)
        external
        onlyRole(MANAGER_ROLE)
    {
        for (uint256 idx; idx < delSigners.length; ++idx) {
            deploySigners.remove(delSigners[idx]);
        }
        for (uint256 idx; idx < addSigners.length; ++idx) {
            deploySigners.add(addSigners[idx]);
        }
        emit ProtocolChanged("DeploySignersChanged", abi.encode(addSigners, delSigners));
    }

    /**
     * @notice Sets whether the factory is enabled. Can be used to effectively
     * stop the factory in the event that we need to switch to a new one.
     */
    function setEnabled(bool _isEnabled) external onlyRole(MANAGER_ROLE) {
        isEnabled = _isEnabled;
        emit ProtocolChanged("SetEnabled", abi.encode(_isEnabled));
    }

    /**
     * @notice Sets the implementation for the collection contract.
     */
    function setCollectionImplementation(address _collectionImpl) external onlyRole(MANAGER_ROLE) {
        collectionImpl = _collectionImpl;
        emit ProtocolChanged("SetCollectionImplementation", abi.encode(_collectionImpl));
    }
}
