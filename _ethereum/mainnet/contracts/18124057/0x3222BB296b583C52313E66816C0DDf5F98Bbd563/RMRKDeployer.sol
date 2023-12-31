//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.15;

import "./Context.sol";
import "./RMRKEquippableWithInitialAssets.sol";
import "./IRMRKDeployer.sol";

error RMRKNotMintaur();

contract RMRKDeployer is IRMRKDeployer, Context {
    address private _owner;
    address private _minter; // Calls the mint
    address private _mintaur; // Calls the deploy

    /**
     * @dev Initializes the contract by setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
    }

    /**
     * @notice Sets the minter address.
     * @dev Can only be called by the contract owner.
     */
    function setMinter(address newMinter) external {
        if (_owner != _msgSender()) revert RMRKNotOwner();
        _minter = newMinter;
    }

    /**
     * @notice Sets the mintaur address.
     * @dev Can only be called by the contract owner.
     */
    function setMintaur(address newMintaur) external {
        if (_owner != _msgSender()) revert RMRKNotOwner();
        _mintaur = newMintaur;
    }

    /**
     * @inheritdoc IRMRKDeployer
     */
    function deployCollection(
        string memory name,
        string memory symbol,
        string memory collectionMetadata,
        uint256 maxSupply,
        address collectionOwner,
        address royaltyRecipient,
        uint16 royaltyPercentageBps,
        string[] memory initialAssetsMetadata
    ) external returns (address newCollection) {
        if (_mintaur != _msgSender()) revert RMRKNotMintaur();

        RMRKEquippableWithInitialAssets wrappedCollection = new RMRKEquippableWithInitialAssets(
                name,
                symbol,
                collectionMetadata,
                maxSupply,
                royaltyRecipient,
                royaltyPercentageBps,
                initialAssetsMetadata,
                _minter
            );

        wrappedCollection.transferOwnership(collectionOwner);

        return address(wrappedCollection);
    }
}
