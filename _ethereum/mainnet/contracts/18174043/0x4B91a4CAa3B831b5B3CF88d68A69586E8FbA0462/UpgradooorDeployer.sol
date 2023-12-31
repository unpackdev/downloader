//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.15;

import "./IERC20.sol";
import "./Context.sol";
import "./RMRKWrappedEquippable.sol";
import "./IUpgradooorDeployer.sol";

error NotOwner();
error NotWrapper();

contract UpgradooorDeployer is IUpgradooorDeployer, Context {
    address private _owner;
    address private _wrapper;

    /**
     * @dev Initializes the contract by setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
    }

    /**
     * @notice Sets the wrapper address.
     * @dev Can only be called by the contract owner.
     */
    function setWrapper(address newWrapper) external {
        if (_owner != _msgSender()) revert NotOwner();
        _wrapper = newWrapper;
    }

    /**
     * @inheritdoc IUpgradooorDeployer
     */
    function wrapCollection(
        address originalCollection,
        uint256 maxSupply,
        address royaltiesRecipient,
        uint256 royaltyPercentageBps,
        string memory collectionMetadataURI
    ) external returns (address) {
        if (_wrapper != _msgSender()) revert NotWrapper();
        string memory name = IERC721Metadata(originalCollection).name();
        string memory symbol = IERC721Metadata(originalCollection).symbol();
        symbol = string.concat("w", symbol);

        RMRKWrappedEquippable wrappedCollection = new RMRKWrappedEquippable(
            originalCollection,
            maxSupply,
            royaltiesRecipient,
            royaltyPercentageBps,
            name,
            symbol,
            collectionMetadataURI
        );

        wrappedCollection.transferOwnership(_wrapper);

        return address(wrappedCollection);
    }
}
