// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// Local References
import "./OwnableDeferral.sol";
import "./IChainNativeMetadataProducer.sol";

/**
 * @title ChainNativeMetadataConsumer
 * @author @NiftyMike | @NFTCulture
 * @dev Basic implementation to manage connections to an external source for NFT metadata.
 */
abstract contract ChainNativeMetadataConsumer is OwnableDeferral {
    // External contract that manages the collection's metadata in a chain-native way.
    IChainNativeMetadataProducer private _metadataProducer;

    constructor(address __metadataProducer) {
        _setProducer(__metadataProducer);
    }

    /**
     * @notice Set the on-chain metadata producer contract.
     * Can only be called if caller is owner.
     *
     * @param __metadataProducer address of the producer contract.
     */
    function setProducer(address __metadataProducer) external isOwner {
        _setProducer(__metadataProducer);
    }

    function _setProducer(address __metadataProducer) internal {
        if (__metadataProducer != address(0)) {
            _metadataProducer = IChainNativeMetadataProducer(__metadataProducer);
        }
    }

    function _getProducer() internal view virtual returns (IChainNativeMetadataProducer) {
        return _metadataProducer;
    }
}
