// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// Local References
import "./OwnableDeferral.sol";
import "./IChainNativeArtProducer.sol";

/**
 * @title SimpleChainNativeArtConsumer
 * @author @NiftyMike | @NFTCulture
 * @dev Basic implementation to manage connections to an external source for NFT art.
 */
abstract contract SimpleChainNativeArtConsumer is OwnableDeferral {
    // External contract that manages the collection's art in a chain-native way.
    IChainNativeArtProducer private _artProducer;

    constructor(address __artProducer) {
        _setProducer(__artProducer);
    }

    /**
     * @notice Set the on-chain art producer contract.
     * Can only be called if caller is owner.
     *
     * @param __artProducer address of the producer contract.
     */
    function setProducer(address __artProducer) external isOwner {
        _setProducer(__artProducer);
    }

    function _setProducer(address __artProducer) internal {
        if (__artProducer != address(0)) {
            _artProducer = IChainNativeArtProducer(__artProducer);
        }
    }

    function _getProducer() internal view virtual returns (IChainNativeArtProducer) {
        return _artProducer;
    }
}
