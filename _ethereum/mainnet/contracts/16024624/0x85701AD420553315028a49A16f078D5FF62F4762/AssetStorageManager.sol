// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity 0.8.16;

import "./IBucketStorage.sol";
import "./Compressed.sol";

import "./InflateLibWrapper.sol";
import "./IndexedBucketLib.sol";

import "./LayerStorageMapping.sol";
import "./LayerStorageDeployer.sol";
import "./TraitStorageMapping.sol";
import "./TraitStorageDeployer.sol";

/**
 * @notice Keeps records of all deployed BucketStorages that contain artwork
 * layer or trait data and provides an abstraction layer that allows data to be
 * accessed via (type, index) pairs.
 */
contract AssetStorageManager {
    using IndexedBucketLib for bytes;
    using PublicInflateLibWrapper for Compressed;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Bundle of `BucketStorage`s containing artwork layer data.
     */
    LayerStorageDeployer.Bundle private _layerBundle;

    /**
     * @notice Bundle of `BucketStorage`s containing trait data.
     */
    TraitStorageDeployer.Bundle private _traitBundle;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    /**
     * @dev Intended to be constructed using the bundles returned by the
     * `*StorageDeployer` helper contracts.
     */
    constructor(
        LayerStorageDeployer.Bundle memory layerBundle_,
        TraitStorageDeployer.Bundle memory traitBundle_
    ) {
        _layerBundle = layerBundle_;
        _traitBundle = traitBundle_;
    }

    /**
     * @notice Retrieves a given layer from storage.
     * @dev Uses the generated storage mapping to identify the storage
     * coordinates of the desired (type, index) pair.
     * @return Uncompressed layer BGR pixels.
     */
    function loadLayer(LayerType layerType, uint256 layerID)
        public
        view
        returns (bytes memory)
    {
        LayerStorageMapping.StorageCoordinates
            memory coordinates = LayerStorageMapping.locate(layerType, layerID);

        return
            _layerBundle
                .storages[coordinates.bucket.storageId]
                .getBucket(coordinates.bucket.bucketId)
                .inflate()
                .getField(coordinates.fieldId);
    }

    /**
     * @notice Retrieves a given trait from storage.
     * @dev Uses the generated storage mapping to identify the storage
     * coordinates of the desired (type, index) pair.
     * @return Uncompressed trait string.
     */
    function loadTrait(TraitType traitType, uint256 traitID)
        public
        view
        returns (string memory)
    {
        TraitStorageMapping.StorageCoordinates
            memory coordinates = TraitStorageMapping.locate(traitType, traitID);

        return
            string(
                _traitBundle
                    .storages[coordinates.bucket.storageId]
                    .getBucket(coordinates.bucket.bucketId)
                    .inflate()
                    .getField(coordinates.fieldId)
            );
    }
}
