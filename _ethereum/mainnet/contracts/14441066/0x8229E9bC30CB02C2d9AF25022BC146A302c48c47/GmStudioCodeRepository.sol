// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 GmDAO
pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./DynamicBuffer.sol";

import "./IGmStudioBlobStorage.sol";
import "./GmStudioBlobStorage.sol";

//                                           __                    __ __
//                                          |  \                  |  \  \
//   ______  ______ ____           _______ _| ▓▓_   __    __  ____| ▓▓\▓▓ ______
//  /      \|      \    \         /       \   ▓▓ \ |  \  |  \/      ▓▓  \/      \
// |  ▓▓▓▓▓▓\ ▓▓▓▓▓▓\▓▓▓▓\       |  ▓▓▓▓▓▓▓\▓▓▓▓▓▓ | ▓▓  | ▓▓  ▓▓▓▓▓▓▓ ▓▓  ▓▓▓▓▓▓\
// | ▓▓  | ▓▓ ▓▓ | ▓▓ | ▓▓        \▓▓    \  | ▓▓ __| ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓ ▓▓  | ▓▓
// | ▓▓__| ▓▓ ▓▓ | ▓▓ | ▓▓__      _\▓▓▓▓▓▓\ | ▓▓|  \ ▓▓__/ ▓▓ ▓▓__| ▓▓ ▓▓ ▓▓__/ ▓▓
//  \▓▓    ▓▓ ▓▓ | ▓▓ | ▓▓  \    |       ▓▓  \▓▓  ▓▓\▓▓    ▓▓\▓▓    ▓▓ ▓▓\▓▓    ▓▓
//  _\▓▓▓▓▓▓▓\▓▓  \▓▓  \▓▓\▓▓     \▓▓▓▓▓▓▓    \▓▓▓▓  \▓▓▓▓▓▓  \▓▓▓▓▓▓▓\▓▓ \▓▓▓▓▓▓
// |  \__| ▓▓
//  \▓▓    ▓▓
//   \▓▓▓▓▓▓
//
contract GmStudioCodeRepository is Ownable {
    using DynamicBuffer for bytes;

    /// @notice The possible types of registered collections.
    enum CollectionType {
        Unknown,
        OnChain,
        InChain
    }

    /// @notice The data entries for a collection.
    /// @dev `id` corresponds to the index in `collectionList`
    /// `exists` is used to indicate if a collection is in the repo (due to zero
    /// default values of mappings)
    /// `locked` if a collection cannot be changed anymore
    /// `collectionType` indicates if the collection is on- or in-chain
    /// `storageContracts` is the list of contracts used for code storage
    /// `artist` is the artist address used to sign the registry entry (equals
    /// zero if the entry is not signed)
    /// `version` allows for possible future versioning requirements.
    struct CollectionData {
        bool locked;
        bool exists;
        CollectionType collectionType;
        uint8 version;
        address artist;
        uint64 id;
        IGmStudioBlobStorage[] storageContracts;
    }

    /// @notice The type and code blob of a given collection.
    /// @dev Return type of `getBlob`
    /// @dev `data` corresponds to a GZip'ed tarball.
    struct CollectionBlob {
        CollectionType collectionType;
        bytes data;
    }

    /// @notice The collection contract addresses in the repository
    address[] internal collectionList;

    /// @notice The collection data in the repository
    mapping(address => CollectionData) internal collectionData;

    /// @notice Managers are addresses are allowed to perform special actions
    /// in place of owner
    mapping(address => bool) public isManager;

    /// @notice The collections supplementary notes. Used for post-lock
    /// informational addendums that are not part of standardized collection
    /// data.
    mapping(address => string[]) internal collectionNotes;

    constructor(address newOwner, address manager_) {
        isManager[manager_] = true;
        _transferOwnership(newOwner);
    }

    // -------------------------------------------------------------------------
    //
    //  Getters
    //
    // -------------------------------------------------------------------------

    /// @notice Returns the list of registered collections in the repository.
    function getCollections() external view returns (address[] memory) {
        return collectionList;
    }

    /// @notice Checks if a registered collection is locked.
    /// @param collection The collection of interest.
    /// @dev Reverts if the collection is not in the repository.
    function isLocked(address collection)
        external
        view
        collectionExists(collection)
        returns (bool)
    {
        return collectionData[collection].locked;
    }

    /// @notice Returns the code blob for a registered collection.
    /// @param collection The collection of interest.
    /// @dev For on-chain projects the return contains a GZip'ed tarball, that
    /// is already concatenated if multiple storage contracts were used.
    /// @dev Reverts if the collection is not in the repository.
    function getBlob(address collection)
        external
        view
        collectionExists(collection)
        returns (CollectionBlob memory)
    {
        CollectionBlob memory blob;
        CollectionData storage data = collectionData[collection];
        blob.collectionType = CollectionType(data.collectionType);

        if (blob.collectionType == CollectionType.InChain) {
            return blob;
        }

        // Concatenate all blobs
        IGmStudioBlobStorage[] storage stores = data.storageContracts;
        uint256 num = stores.length;
        blob.data = DynamicBuffer.allocate(num * 25000);
        for (uint256 idx = 0; idx < num; ++idx) {
            blob.data.appendSafe(stores[idx].getBlob());
        }

        return blob;
    }

    /// @notice Returns the storage addresses for a registered collection.
    /// @param collection The collection of interest.
    /// @dev Reverts if the collection is not in the repository.
    function getStorageContracts(address collection)
        external
        view
        collectionExists(collection)
        returns (IGmStudioBlobStorage[] memory)
    {
        return collectionData[collection].storageContracts;
    }

    /// @notice Returns the registry data for a registered collection.
    /// @param collection The collection of interest.
    /// @dev Reverts if the collection is not in the repository.
    function getCollectionData(address collection)
        external
        view
        collectionExists(collection)
        returns (CollectionData memory)
    {
        return collectionData[collection];
    }

    /// @notice Returns the storage type of a registered collection.
    /// @param collection The collection contract address of interest.
    /// @dev Reverts if the collection is not in the repository.
    function getCollectionType(address collection)
        public
        view
        collectionExists(collection)
        returns (CollectionType)
    {
        return CollectionType(collectionData[collection].collectionType);
    }

    /// @notice Returns the list of notes attached to a registered collection.
    /// @param collection The collection contract address of interest.
    /// @dev Reverts if the collection is not in the repository.
    function getNotes(address collection)
        public
        view
        collectionExists(collection)
        returns (string[] memory)
    {
        return collectionNotes[collection];
    }

    // -------------------------------------------------------------------------
    //
    //  Setters
    //
    // -------------------------------------------------------------------------

    /// @notice A convenience interface to store blobs on-chain
    /// @dev Stores blobs in contract bytecode for efficiency
    /// @param blob The bytes of the blob to be stored
    function store(bytes calldata blob)
        external
        returns (IGmStudioBlobStorage)
    {
        IGmStudioBlobStorage storageContract = new GmStudioBlobStorage(blob);
        emit NewBlobStorage(storageContract);
        return storageContract;
    }

    /// @notice Adds a new collection to the repository.
    /// @param collection The collection of interest.
    /// @param storageContracts The contracts storing the code blobs.
    /// @dev Reverts if the collection already exists.
    function addOnChainCollection(
        address collection,
        IGmStudioBlobStorage[] calldata storageContracts
    ) external onlyManagerOrOwner {
        _addOnChainCollection(collection, storageContracts);
    }

    function addInChainCollection(address collection)
        external
        onlyManagerOrOwner
    {
        _addInchainCollection(collection);
    }

    /// @notice Pops collections from the internal list.
    /// @dev Reverts if the collection is locked.
    function popCollection() external onlyManagerOrOwner {
        _popCollection();
    }

    /// @notice Sets the storage contract addresses for a registered collection.
    /// @param collection The collection of interest.
    /// @param storageContracts The contract storing the code.
    /// @dev Reverts if the collection is locked, is not in the repository, or
    /// is not an on-chain collection.
    /// @dev Invalidates existing artist signatures.
    function setStorageContracts(
        address collection,
        IGmStudioBlobStorage[] calldata storageContracts
    ) external onlyManagerOrOwner {
        _setStorageContracts(collection, storageContracts);
    }

    /// @notice Changes the address of a registered collection.
    /// @param addrOld The previous address of the collection.
    /// @param addrNew The new address of the collection.
    /// @dev Reverts if the collection is locked or is not in the repository.
    /// @dev Invalidates existing artist signatures.
    function setCollectionAddress(address addrOld, address addrNew)
        external
        onlyManagerOrOwner
    {
        _setCollectionAddress(addrOld, addrNew);
    }

    /// @notice Adds a note to a locked collection.
    /// @param collection The collection to have notes added to.
    /// @param note The note to be added. If technical in nature, preferred to
    /// be structured JSON.
    /// @dev Reverts if the collection is not locked or is not in the repository
    function addNote(address collection, string calldata note)
        external
        onlyManagerOrOwner
        onlyLockedExistingCollection(collection)
    {
        collectionNotes[collection].push(note);
    }

    /// @notice Adds an artist to a registered collection.
    /// @param collection The collection of interest.
    /// @param artist The signing artist's address.
    /// @param signature The artist's signature.
    /// @dev Reverts if the collection is not in the repository or is locked, or
    /// if the given signature is invalid.
    /// @dev The signature is not stored explicitly within the contract.
    /// However, this method is the only way to add an artist to a collection.
    /// Hence, a collection can be regarded as signed if the artist is set.
    function addArtistWithSignature(
        address collection,
        address artist,
        bytes calldata signature
    ) external onlyManagerOrOwner {
        _addArtistWithSignature(collection, artist, signature);
    }

    /// @notice Locks a collection.
    /// @param collection The collection to be locked.
    /// @dev Reverts if the collection is locked or is not in the repository.
    function lock(address collection) external onlyOwner {
        _lock(collection);
    }

    /// @notice Sets or removes manager permissions for an address.
    /// @param manager The manager address.
    /// @param status Manager status to be set. True corresponds to granting
    /// elevated permissions.
    function setManager(address manager, bool status) external onlyOwner {
        isManager[manager] = status;
    }

    // -------------------------------------------------------------------------
    //
    //  Internal
    //
    // -------------------------------------------------------------------------

    /// @dev Restrics access to owner and manager
    modifier onlyManagerOrOwner() {
        if (!(msg.sender == owner() || isManager[msg.sender]))
            revert OnlyManagerOrOwner();
        _;
    }

    /// @notice Reverts if a collection is locked or nonexistent.
    modifier onlyUnlockedExistingCollection(address collection) {
        if (!collectionData[collection].exists) revert CollectionNotFound();
        if (collectionData[collection].locked) revert CollectionIsLocked();
        _;
    }

    /// @notice Reverts if a collection is not locked or nonexistent.
    modifier onlyLockedExistingCollection(address collection) {
        if (!collectionData[collection].exists) revert CollectionNotFound();
        if (!collectionData[collection].locked) revert CollectionIsNotLocked();
        _;
    }

    /// @notice Reverts if a collection is nonexistent.
    modifier collectionExists(address collection) {
        if (!collectionData[collection].exists) revert CollectionNotFound();
        _;
    }

    /// @notice Reverts if a collection.isOnChain does not match onChain.
    modifier hasCollectionType(
        address collection,
        CollectionType collectionType
    ) {
        if (
            CollectionType(collectionData[collection].collectionType) !=
            collectionType
        ) {
            revert WrongCollectionType(
                collectionData[collection].collectionType
            );
        }
        _;
    }

    /// @notice Reverts if a collection exists.
    modifier onlyNewCollections(address collection) {
        if (collectionData[collection].exists) revert CollectionAlreadyExists();
        _;
    }

    /// @notice Reverts if at least one of the given storageContracts does not
    /// satisfy the IGmStudioBlobStorage interface according to EIP-165.
    modifier onlyValidStorageContracts(
        IGmStudioBlobStorage[] calldata storageContracts
    ) {
        uint256 num = storageContracts.length;
        for (uint256 idx = 0; idx < num; ++idx) {
            (bool success, bytes memory returnData) = address(
                storageContracts[idx]
            ).call(
                    abi.encodePacked(
                        IERC165.supportsInterface.selector,
                        abi.encode(type(IGmStudioBlobStorage).interfaceId)
                    )
                );

            if (!success || returnData.length == 0) {
                revert InvalidStorageContract();
            }

            bool supported = abi.decode(returnData, (bool));
            if (!supported) {
                revert InvalidStorageContract();
            }
        }
        _;
    }

    /// @notice Adds a collection
    function _addOnChainCollection(
        address collection,
        IGmStudioBlobStorage[] calldata storageContracts
    )
        internal
        onlyNewCollections(collection)
        onlyValidStorageContracts(storageContracts)
    {
        uint256 nextId = collectionList.length;
        collectionList.push(collection);
        collectionData[collection] = CollectionData({
            locked: false,
            exists: true,
            collectionType: CollectionType.OnChain,
            artist: address(0),
            version: 0,
            id: uint64(nextId),
            storageContracts: storageContracts
        });
    }

    /// @notice Adds a collection
    function _addInchainCollection(address collection)
        internal
        onlyNewCollections(collection)
    {
        uint256 nextId = collectionList.length;
        collectionList.push(collection);
        collectionData[collection] = CollectionData({
            locked: false,
            exists: true,
            collectionType: CollectionType.InChain,
            artist: address(0),
            version: 0,
            id: uint64(nextId),
            storageContracts: new IGmStudioBlobStorage[](0)
        });
    }

    /// @notice Sets the storage contract addresses for a registered colleciton
    function _setStorageContracts(
        address collection,
        IGmStudioBlobStorage[] calldata storageContracts
    )
        internal
        onlyUnlockedExistingCollection(collection)
        hasCollectionType(collection, CollectionType.OnChain)
        onlyValidStorageContracts(storageContracts)
    {
        collectionData[collection].artist = address(0);
        collectionData[collection].storageContracts = storageContracts;
    }

    /// @notice Sets a new contract address for an existing collection.
    /// @dev Overwrites if `id` exists, reverts otherwise.
    /// @dev Reverts if the collection is locked or isn't in the repo.
    function _setCollectionAddress(address addrOld, address addrNew) internal {
        CollectionData memory data = collectionData[addrOld];
        data.artist = address(0);
        collectionData[addrNew] = data;
        collectionList[data.id] = addrNew;
        _removeCollectionData(addrOld);
    }

    /// @notice Pops an existing collection.
    /// @dev Reverts if the latest collection is locked.
    function _popCollection() internal {
        address collection = collectionList[collectionList.length - 1];
        _removeCollectionData(collection);
        collectionList.pop();
    }

    /// @notice Removes a registered collection.
    function _removeCollectionData(address collection)
        internal
        onlyUnlockedExistingCollection(collection)
    {
        delete collectionData[collection];
    }

    /// @notice Locks a collection.
    function _lock(address collection)
        internal
        onlyUnlockedExistingCollection(collection)
    {
        CollectionData storage data = collectionData[collection];
        if (
            (data.collectionType == CollectionType.OnChain &&
                data.storageContracts.length == 0) ||
            data.collectionType == CollectionType.Unknown
        ) revert StorageContractsNotSet();
        collectionData[collection].locked = true;
    }

    /// @notice Adds an artist to a registered collection
    /// @dev Reverts if the signature is invalid.
    function _addArtistWithSignature(
        address collection,
        address artist,
        bytes calldata signature
    ) internal onlyUnlockedExistingCollection(collection) {
        CollectionData storage data = collectionData[collection];
        data.artist = artist;

        bytes32 message = ECDSA.toEthSignedMessageHash(
            abi.encodePacked(collection, data.storageContracts)
        );
        address signer = ECDSA.recover(message, signature);
        if (signer != artist) revert InvalidSignature();
    }

    // -------------------------------------------------------------------------
    //
    //  Events
    //
    // -------------------------------------------------------------------------

    event NewBlobStorage(IGmStudioBlobStorage indexed storageAddress);

    // -------------------------------------------------------------------------
    //
    //  Errors
    //
    // -------------------------------------------------------------------------

    error CollectionIsLocked();
    error CollectionIsNotLocked();
    error WrongCollectionType(CollectionType);
    error CollectionNotFound();
    error OnlyManagerOrOwner();
    error StorageContractsNotSet();
    error CollectionAlreadyExists();
    error InvalidStorageContract();
    error InvalidSignature();
}
