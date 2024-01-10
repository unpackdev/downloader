// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ICollectionFactory.sol";
import "./ICollection.sol";
import "./ICollectionCloneable.sol";
import "./IOwnable.sol";
import "./IHashes.sol";
import "./LibClone.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

/**
 * @title CollectionFactory
 * @author DEX Labs
 * @notice This contract is the registry for Hashes Collections.
 */
contract CollectionFactory is ICollectionFactory, Ownable, ReentrancyGuard {
    /// @notice A checkpoint for ecosystem settings values. Settings are ABI encoded bytes
    ///         to provide the most flexibility towards various implementation contracts.
    struct SettingsCheckpoint {
        uint64 id;
        bytes settings;
    }

    /// @notice A structure for storing the contract addresses of collection instances.
    struct CollectionContracts {
        bool exists;
        bool cloneable;
        address[] contractAddresses;
    }

    IHashes hashesToken;

    /// @notice collections A mapping of implementation addresses to a struct which
    ///         contains an array of the cloned collections for that implementation.
    mapping(address => CollectionContracts) public collections;

    /// @notice ecosystems An array of the hashed ecosystem names which correspond to
    ///         a settings format which can be used by multiple implementation contracts.
    bytes32[] public ecosystems;

    /// @notice ecosystemSettings A mapping of hashed ecosystem names to an array of
    ///         settings checkpoints. Settings checkpoints contain ABI encoded data
    ///         which can be decoded in implementation addresses that consume them.
    mapping(bytes32 => SettingsCheckpoint[]) public ecosystemSettings;

    /// @notice implementationAddresses A mapping of hashed ecosystem names to an array
    ///         of the implementation addresses for that ecosystem.
    mapping(bytes32 => address[]) public implementationAddresses;

    /// @notice factoryMaintainerAddress An address which has some distinct maintenance abilities. These
    ///         include the ability to remove implementation addresses or collection instances, as well as
    ///         transfer this role to another address. Implementation addresses can choose to use this address
    ///         for certain roles since it is passed through to the initialize function upon creating
    ///         a cloned collection.
    address public factoryMaintainerAddress;

    /// @notice ImplementationAddressAdded Emitted when an implementation address is added.
    event ImplementationAddressAdded(address indexed implementationAddress, bool indexed cloneable);

    /// @notice CollectionCreated Emitted when a Collection is created.
    event CollectionCreated(
        address indexed implementationAddress,
        address indexed collectionAddress,
        address indexed creator
    );

    /// @notice FactoryMaintainerAddressSet Emitted when the factory maintainer address is set.
    event FactoryMaintainerAddressSet(address indexed factoryMaintainerAddress);

    /// @notice ImplementationAddressesRemoved Emitted when implementation addresses are removed.
    event ImplementationAddressesRemoved(address[] implementationAddresses);

    /// @notice CollectionAddressRemoved Emitted when a cloned collection contract address is removed.
    event CollectionAddressRemoved(address indexed implementationAddress, address indexed collectionAddress);

    /// @notice EcosystemSettingsCreated Emitted when ecosystem settings are created.
    event EcosystemSettingsCreated(string ecosystemName, bytes32 indexed hashedEcosystemName, bytes settings);

    /// @notice EcosystemSettingsUpdated Emitted when ecosystem settings are updated.
    event EcosystemSettingsUpdated(bytes32 indexed hashedEcosystemName, bytes settings);

    modifier onlyOwnerOrFactoryMaintainer() {
        require(
            _msgSender() == factoryMaintainerAddress || _msgSender() == owner(),
            "CollectionFactory: must be either factory maintainer or owner"
        );
        _;
    }

    /**
     * @notice Constructor for the Collection Factory.
     */
    constructor(IHashes _hashesToken) {
        // initially set the factoryMaintainerAddress to be the deployer, though this can transfered
        factoryMaintainerAddress = _msgSender();
        hashesToken = _hashesToken;

        // make HashesDAO the owner of this Factory contract
        transferOwnership(IOwnable(address(hashesToken)).owner());
    }

    /**
     * @notice This function adds an implementation address.
     * @param _hashedEcosystemName The ecosystem which this implementation address will reference.
     * @param _implementationAddress The address of the Collection contract.
     * @param _cloneable Whether this implementation address is cloneable.
     */
    function addImplementationAddress(
        bytes32 _hashedEcosystemName,
        address _implementationAddress,
        bool _cloneable
    ) external override {
        require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem doesn't exist");
        CollectionContracts storage collection = collections[_implementationAddress];
        require(!collection.exists, "CollectionFactory: implementation address already exists");
        require(_implementationAddress != address(0), "CollectionFactory: implementation address cannot be 0 address");

        uint64 blockNumber = safe64(block.number, "CollectionFactory: exceeds 64 bits.");
        require(
            ICollection(_implementationAddress).verifyEcosystemSettings(
                getCheckpointedSettings(ecosystemSettings[_hashedEcosystemName], blockNumber)
            ),
            "CollectionFactory: implementation address doesn't properly validate ecosystem settings"
        );

        collection.exists = true;
        collection.cloneable = _cloneable;

        implementationAddresses[_hashedEcosystemName].push(_implementationAddress);

        emit ImplementationAddressAdded(_implementationAddress, _cloneable);
    }

    /**
     * @notice This function clones a Hashes Collection implementation contract.
     * @param _implementationAddress The address of the cloneable implementation contract.
     * @param _initializationData The abi encoded initialization data which is consumable
     *        by the implementation contract in its initialize function.
     */
    function createCollection(address _implementationAddress, bytes memory _initializationData)
        external
        override
        nonReentrant
    {
        CollectionContracts storage collection = collections[_implementationAddress];
        require(collection.exists, "CollectionFactory: implementation address not found.");
        require(collection.cloneable, "CollectionFactory: implementation address is not cloneable.");

        ICollectionCloneable clonedCollection = ICollectionCloneable(LibClone.createClone(_implementationAddress));
        collection.contractAddresses.push(address(clonedCollection));

        clonedCollection.initialize(hashesToken, factoryMaintainerAddress, _msgSender(), _initializationData);

        emit CollectionCreated(_implementationAddress, address(clonedCollection), _msgSender());
    }

    /**
     * @notice This function sets the factory maintainer address.
     * @param _factoryMaintainerAddress The address of the factory maintainer.
     */
    function setFactoryMaintainerAddress(address _factoryMaintainerAddress)
        external
        override
        onlyOwnerOrFactoryMaintainer
    {
        factoryMaintainerAddress = _factoryMaintainerAddress;
        emit FactoryMaintainerAddressSet(_factoryMaintainerAddress);
    }

    /**
     * @notice This function removes implementation addresses from the factory.
     * @param _hashedEcosystemNames The ecosystems which these implementation addresses reference.
     * @param _implementationAddressesToRemove The implementation addresses to remove: either cloneable
     *        implementation addresses or a standalone contracts.
     * @param _indexes The array indexes to be removed. Must be monotonically increasing and match the items
     *        in the other two arrays. This array is provided to reduce the cost of removal.
     */
    function removeImplementationAddresses(
        bytes32[] memory _hashedEcosystemNames,
        address[] memory _implementationAddressesToRemove,
        uint256[] memory _indexes
    ) external override onlyOwnerOrFactoryMaintainer {
        require(
            _hashedEcosystemNames.length == _implementationAddressesToRemove.length &&
                _hashedEcosystemNames.length == _indexes.length,
            "CollectionFactory: arrays provided must be the same length"
        );

        // set this to max int to start so first less-than comparison is always true
        uint256 _previousIndex = 2**256 - 1;

        // iterate through items in reverse order
        for (uint256 i = 0; i < _indexes.length; i++) {
            require(
                _indexes[_indexes.length - 1 - i] < _previousIndex,
                "CollectionFactory: arrays must be ordered before processing."
            );
            _previousIndex = _indexes[_indexes.length - 1 - i];

            bytes32 _hashedEcosystemName = _hashedEcosystemNames[_indexes.length - 1 - i];
            address _implementationAddress = _implementationAddressesToRemove[_indexes.length - 1 - i];
            uint256 _currentIndex = _indexes[_indexes.length - 1 - i];

            require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem doesn't exist");
            require(collections[_implementationAddress].exists, "CollectionFactory: implementation address not found.");
            address[] storage _implementationAddresses = implementationAddresses[_hashedEcosystemName];
            require(_currentIndex < _implementationAddresses.length, "CollectionFactory: array index out of bounds.");
            require(
                _implementationAddresses[_currentIndex] == _implementationAddress,
                "CollectionFactory: element at array index not equal to implementation address."
            );

            // remove the implementation address from the mapping
            delete collections[_implementationAddress];

            // swap the last element of the array for the one we're removing
            _implementationAddresses[_currentIndex] = _implementationAddresses[_implementationAddresses.length - 1];
            _implementationAddresses.pop();
        }

        emit ImplementationAddressesRemoved(_implementationAddressesToRemove);
    }

    /**
     * @notice This function removes a cloned collection address from the factory.
     * @param _implementationAddress The implementation address of the cloneable contract.
     * @param _collectionAddress The cloned collection address to be removed.
     * @param _index The array index to be removed. This is provided to reduce the cost of removal.
     */
    function removeCollection(
        address _implementationAddress,
        address _collectionAddress,
        uint256 _index
    ) external override onlyOwnerOrFactoryMaintainer {
        CollectionContracts storage collection = collections[_implementationAddress];
        require(collection.exists, "CollectionFactory: implementation address not found.");
        require(_index < collection.contractAddresses.length, "CollectionFactory: array index out of bounds.");
        require(
            collection.contractAddresses[_index] == _collectionAddress,
            "CollectionFactory: element at array index not equal to collection address."
        );

        // swap the last element of the array for the one we're removing
        collection.contractAddresses[_index] = collection.contractAddresses[collection.contractAddresses.length - 1];
        collection.contractAddresses.pop();

        emit CollectionAddressRemoved(_implementationAddress, _collectionAddress);
    }

    /**
     * @notice This function creates a new ecosystem setting key in the mapping along with
     *         the initial ABI encoded settings value to be used for that key. The factory maintainer
     *         can create a new ecosystem setting to allow for efficient bootstrapping of a new
     *         ecosystem, but only HashesDAO can update an existing ecosystem.
     * @param _ecosystemName The name of the ecosystem.
     * @param _settings The ABI encoded settings data which can be decoded by implementation
     *        contracts which consume this ecosystem.
     */
    function createEcosystemSettings(string memory _ecosystemName, bytes memory _settings)
        external
        override
        onlyOwnerOrFactoryMaintainer
    {
        bytes32 hashedEcosystemName = keccak256(abi.encodePacked(_ecosystemName));
        require(
            ecosystemSettings[hashedEcosystemName].length == 0,
            "CollectionFactory: ecosystem settings for this name already exist"
        );

        uint64 blockNumber = safe64(block.number, "CollectionFactory: exceeds 64 bits.");
        ecosystemSettings[hashedEcosystemName].push(SettingsCheckpoint({ id: blockNumber, settings: _settings }));

        ecosystems.push(hashedEcosystemName);

        emit EcosystemSettingsCreated(_ecosystemName, hashedEcosystemName, _settings);
    }

    /**
     * @notice This function updates an ecosystem setting which means a new checkpoint is
     *         added to the array of settings checkpoints for that ecosystem. Only HashesDAO
     *         can call this function since these are likely to be more established ecosystems
     *         which have more impact.
     * @param _hashedEcosystemName The hashed name of the ecosystem.
     * @param _settings The ABI encoded settings data which can be decoded by implementation
     *        contracts which consume this ecosystem.
     */
    function updateEcosystemSettings(bytes32 _hashedEcosystemName, bytes memory _settings) external override onlyOwner {
        require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem settings not found");
        require(
            implementationAddresses[_hashedEcosystemName].length > 0,
            "CollectionFactory: no implementation addresses for this ecosystem"
        );

        ICollection firstImplementationAddress = ICollection(implementationAddresses[_hashedEcosystemName][0]);
        require(
            firstImplementationAddress.verifyEcosystemSettings(_settings),
            "CollectionFactory: invalid ecosystem settings according to first implementation contract"
        );

        uint64 blockNumber = safe64(block.number, "CollectionFactory: exceeds 64 bits.");
        ecosystemSettings[_hashedEcosystemName].push(SettingsCheckpoint({ id: blockNumber, settings: _settings }));

        emit EcosystemSettingsUpdated(_hashedEcosystemName, _settings);
    }

    /**
     * @notice This function gets the ecosystem settings from a particular ecosystem checkpoint.
     * @param _hashedEcosystemName The hashed name of the ecosystem.
     * @param _blockNumber The block number in which the new Collection was initialized. This is
     *        used to determine which settings were active at the time of Collection creation.
     */
    function getEcosystemSettings(bytes32 _hashedEcosystemName, uint64 _blockNumber)
        external
        view
        override
        returns (bytes memory)
    {
        require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem settings not found");

        return getCheckpointedSettings(ecosystemSettings[_hashedEcosystemName], _blockNumber);
    }

    /**
     * @notice This function returns an array of the Hashes Collections
     *         created through this registry for a particular implementation address.
     * @param _implementationAddress The implementation address.
     * @return An array of Collection addresses.
     */
    function getCollections(address _implementationAddress) external view override returns (address[] memory) {
        require(collections[_implementationAddress].exists, "CollectionFactory: implementation address not found.");
        return collections[_implementationAddress].contractAddresses;
    }

    /**
     * @notice This function returns an array of the Hashes Collections
     *         created through this registry for a particular implementation address.
     * @param _implementationAddress The implementation address.
     * @param _start The array start index (inclusive).
     * @param _end The array end index (exclusive).
     * @return An array of Collection addresses.
     */
    function getCollections(
        address _implementationAddress,
        uint256 _start,
        uint256 _end
    ) external view override returns (address[] memory) {
        CollectionContracts storage collection = collections[_implementationAddress];

        require(collection.exists, "CollectionFactory: implementation address not found.");
        require(
            _start < collection.contractAddresses.length &&
                _end <= collection.contractAddresses.length &&
                _end > _start,
            "CollectionFactory: Array indices out of bounds"
        );

        address[] memory collectionsForImplementation = new address[](_end - _start);
        for (uint256 i = _start; i < _end; i++) {
            collectionsForImplementation[i] = collection.contractAddresses[i];
        }
        return collectionsForImplementation;
    }

    /**
     * @notice This function gets the list of hashed ecosystem names.
     * @return An array of the hashed ecosystem names.
     */
    function getEcosystems() external view override returns (bytes32[] memory) {
        return ecosystems;
    }

    /**
     * @notice This function gets the list of hashed ecosystem names.
     * @param _start The array start index (inclusive).
     * @param _end The array end index (exclusive).
     * @return An array of the hashed ecosystem names.
     */
    function getEcosystems(uint256 _start, uint256 _end) external view override returns (bytes32[] memory) {
        require(
            _start < ecosystems.length && _end <= ecosystems.length && _end > _start,
            "CollectionFactory: Array indices out of bounds"
        );

        bytes32[] memory _ecosystems = new bytes32[](_end - _start);
        for (uint256 i = _start; i < _end; i++) {
            _ecosystems[i] = ecosystems[i];
        }
        return _ecosystems;
    }

    /**
     * @notice This function returns an array of the implementation addresses.
     * @param _hashedEcosystemName The ecosystem to fetch implementation addresses from.
     * @return Array of Hashes Collection implementation addresses.
     */
    function getImplementationAddresses(bytes32 _hashedEcosystemName)
        external
        view
        override
        returns (address[] memory)
    {
        require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem doesn't exist");
        return implementationAddresses[_hashedEcosystemName];
    }

    /**
     * @notice This function returns an array of the implementation addresses.
     * @param _hashedEcosystemName The ecosystem to fetch implementation addresses from.
     * @param _start The array start index (inclusive).
     * @param _end The array end index (exclusive).
     * @return Array of Hashes Collection implementation addresses.
     */
    function getImplementationAddresses(
        bytes32 _hashedEcosystemName,
        uint256 _start,
        uint256 _end
    ) external view override returns (address[] memory) {
        require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem doesn't exist");
        require(
            _start < implementationAddresses[_hashedEcosystemName].length &&
                _end <= implementationAddresses[_hashedEcosystemName].length &&
                _end > _start,
            "CollectionFactory: Array indices out of bounds"
        );

        address[] memory _implementationAddresses = new address[](_end - _start);
        for (uint256 i = _start; i < _end; i++) {
            _implementationAddresses[i] = implementationAddresses[_hashedEcosystemName][i];
        }
        return _implementationAddresses;
    }

    function getCheckpointedSettings(SettingsCheckpoint[] storage _settingsCheckpoints, uint64 _blockNumber)
        private
        view
        returns (bytes storage)
    {
        require(
            _blockNumber >= _settingsCheckpoints[0].id,
            "CollectionFactory: Block number before first settings block"
        );

        // If blocknumber greater than highest checkpoint, just return the latest checkpoint
        if (_blockNumber >= _settingsCheckpoints[_settingsCheckpoints.length - 1].id)
            return _settingsCheckpoints[_settingsCheckpoints.length - 1].settings;

        // Binary search for the matching checkpoint
        uint256 min = 0;
        uint256 max = _settingsCheckpoints.length - 1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;

            if (_settingsCheckpoints[mid].id == _blockNumber) {
                return _settingsCheckpoints[mid].settings;
            }
            if (_settingsCheckpoints[mid].id < _blockNumber) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return _settingsCheckpoints[min].settings;
    }

    function safe64(uint256 n, string memory errorMessage) internal pure returns (uint64) {
        require(n < 2**64, errorMessage);
        return uint64(n);
    }
}
