// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ICollection.sol";
import "./ICollectionCloneable.sol";
import "./ICollectionNFTCloneableV1.sol";
import "./IHashes.sol";
import "./OwnableCloneable.sol";
import "./PaymentSplitterCloneable.sol";

/**
 * @title CollectionPaymentSplitterCloneable
 * @author DEX Labs
 * @notice Cloneable payment splitter contract with methods to interace with Hashes Collections.
 *         A payment splitter is useful in cases where there are multiple parties collaborating
 *         on a project, and mint fees/royalties need to be sent to multiple addresses with
 *         different percentage allocations.
 */
contract CollectionPaymentSplitterCloneable is
    ICollection,
    ICollectionCloneable,
    PaymentSplitterCloneable,
    OwnableCloneable
{
    bool _initialized;

    /// @notice CollectionPaymentSplitterInitialited Emitted when a Collection Payment Splitter is initialized.
    event CollectionPaymentSplitterInitialized(address[] payees, uint256[] shares);

    modifier initialized() {
        require(_initialized, "CollectionPaymentSplitterCloneable: hasn't been initialized yet.");
        _;
    }

    /**
     * @notice This function is used by the Factory to verify the format of ecosystem settings
     * @param _settings ABI encoded ecosystem settings data. This should be empty for the 'Default' ecosystem.
     *
     * @return The boolean result of the validation.
     */
    function verifyEcosystemSettings(bytes memory _settings) external pure override returns (bool) {
        return _settings.length == 0;
    }

    /**
     * @notice This function initializes a cloneable implementation contract.
     * @param _createCollectionCaller The address which has called createCollection on the factory.
     *        This will become the Owner of this contract.
     * @param _initializationData ABI encoded initialization data. This expected encoding is the
     *        following:
     *
     *        'address[]' payees - Addresses of the payees for this payment splitter (the shareholders).
     *        'uint256[]' shares - The payment splitter share amounts corresponding to the payees.
     */
    function initialize(
        IHashes,
        address,
        address _createCollectionCaller,
        bytes memory _initializationData
    ) external override {
        require(!_initialized, "CollectionPaymentSplitter: already initialized.");

        initializeOwnership(_createCollectionCaller);

        (address[] memory _payees, uint256[] memory _shares) = abi.decode(_initializationData, (address[], uint256[]));
        initializeSplitter(_payees, _shares);

        _initialized = true;

        emit CollectionPaymentSplitterInitialized(_payees, _shares);
    }

    /**
     * @notice Function for setting the baseTokenURI on the associated Collection.
     * @param _baseTokenURI The base token URI.
     */
    function setBaseTokenURI(ICollectionNFTCloneableV1 collection, string memory _baseTokenURI)
        external
        initialized
        onlyOwner
    {
        collection.setBaseTokenURI(_baseTokenURI);
    }

    /**
     * @notice Function for setting the royalty bps on the associated Collection.
     * @param _royaltyBps The royalty bps.
     */
    function setRoyaltyBps(ICollectionNFTCloneableV1 collection, uint16 _royaltyBps) external initialized onlyOwner {
        collection.setRoyaltyBps(_royaltyBps);
    }

    /**
     * @notice Function for transfering the creator address on the associated Hashes Collection.
     * @param _creatorAddress The creator address.
     */
    function transferCreator(ICollectionNFTCloneableV1 collection, address _creatorAddress)
        external
        initialized
        onlyOwner
    {
        collection.transferCreator(_creatorAddress);
    }
}
