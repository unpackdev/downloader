pragma solidity 0.8.12;

import "./IRoyaltyFeeManager.sol";
import "./ICollectionRegistry.sol";
import "./ExchangeCore.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

import "./IRewards.sol";

abstract contract ExchangeManager is ExchangeCore {
    event ProtocolFeesRecipientUpdated(address indexed recipient);
    event ProtocolFeesPercentageUpdated(uint256 percentage);
    event SpecialCollectionProtocolFeesUpdated(
        address collection,
        uint256 percentage
    );
    event RoyaltyManagerUpdated(address indexed royaltyManager);
    event CollectionRegistryUpdated(address indexed collectionRegistry);
    event WhitelistedCustomCollectionUpdated(address collection, bool state);
    event BlackListedCollectionUpdated(address collection, bool state);
    event BlackListedUserUpdated(address account, bool state);

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateProtocolFeesPercentage(uint256 newPercentage)
        external
        onlyOwner
        returns (uint256)
    {
        if (newPercentage > 5_000) revert InvalidArg("max newPercentage");

        if (newPercentage == protocolFeesPercentage)
            revert RejectedAlreadyInState();

        protocolFeesPercentage = newPercentage;
        emit ProtocolFeesPercentageUpdated(newPercentage);
        return newPercentage;
    }

    function updateSpecialProtocolFeesPercentage(
        address collection,
        uint256 percentage
    ) external onlyOwner returns (uint256) {
        if (percentage > 5_000) revert InvalidArg("max newPercentage");

        if (collection == address(0)) revert RejectedNullishAddress();

        if (specialProtocolFeesPercentage[collection] == percentage)
            revert RejectedAlreadyInState();

        specialProtocolFeesPercentage[collection] = percentage;
        emit SpecialCollectionProtocolFeesUpdated(collection, percentage);
        return percentage;
    }

    function updateProtocolFeesRecipient(address newRecipient)
        external
        onlyOwner
        returns (address)
    {
        if (newRecipient == address(0)) revert RejectedNullishAddress();
        protocolFeesRecipient = newRecipient;
        emit ProtocolFeesRecipientUpdated(newRecipient);
        return newRecipient;
    }

    /**
     * @dev Update {royaltyManager}
     * @notice {onlyOwner} protected
     */
    function updateRoyaltyManager(address newRoyaltyManager)
        external
        onlyOwner
        returns (address)
    {
        if (newRoyaltyManager == address(0)) revert RejectedNullishAddress();
        royaltyManager = IRoyaltyFeeManager(newRoyaltyManager);
        emit RoyaltyManagerUpdated(newRoyaltyManager);
        return newRoyaltyManager;
    }

    /**
     * @dev Update {rewardsManager}
     * @notice {onlyOwner} protected
     */
    function updateRewardsManager(address newRewardsManager)
        external
        onlyOwner
        returns (address)
    {
        if (newRewardsManager == address(0)) revert RejectedNullishAddress();
        rewardsManager = IRewards(newRewardsManager);
        emit RoyaltyManagerUpdated(newRewardsManager);
        return newRewardsManager;
    }

    function updateCollectionRegistry(address newCollectionRegistry)
        external
        onlyOwner
        returns (address)
    {
        if (newCollectionRegistry == address(0))
            revert RejectedNullishAddress();
        collectionRegistry = ICollectionRegistry(newCollectionRegistry);
        emit CollectionRegistryUpdated(newCollectionRegistry);
        return newCollectionRegistry;
    }

    function updateWhitelistedCustomCollection(address collection, bool state)
        external
        onlyOwner
        returns (bool)
    {
        if (collection == address(0)) revert RejectedNullishAddress();

        if (whitelistedCustomCollection[collection] == state)
            revert RejectedAlreadyInState();

        whitelistedCustomCollection[collection] = state;
        emit WhitelistedCustomCollectionUpdated(collection, state);
        return true;
    }

    function updateBlacklistedUser(address account, bool state)
        external
        onlyOwner
        returns (bool)
    {
        if (account == address(0)) revert RejectedNullishAddress();

        if (blackListedUser[account] == state) revert RejectedAlreadyInState();

        blackListedUser[account] = state;
        emit BlackListedUserUpdated(account, state);
        return true;
    }

    function updateBlackListedCollection(address collection, bool state)
        external
        onlyOwner
        returns (bool)
    {
        if (collection == address(0)) revert RejectedNullishAddress();

        if (blackListedCollection[collection] == state)
            revert RejectedAlreadyInState();

        blackListedCollection[collection] = state;
        emit BlackListedCollectionUpdated(collection, state);
        return true;
    }

    function withdrawStuckETH(uint256 amount, address to)
        external
        onlyOwner
        nonReentrant
    {
        payable(to).transfer(amount);
        emit StuckEthWithdrawn(amount);
    }

    function withdrawStuckETHFrom(address from, address to)
        external
        onlyOwner
        nonReentrant
    {
        uint256 amount = failedEthTransfer[from];

        if (amount == 0) revert();

        delete failedEthTransfer[from];

        payable(to).transfer(amount);

        emit StuckEthWithdrawn(amount);
        emit FailedEthWithdrawn(from, to, amount);
    }

    function transferStuckERC721(
        address collection,
        uint256 tokenId,
        address to
    ) external onlyOwner nonReentrant {
        IERC721(collection).safeTransferFrom(address(this), to, tokenId);

        emit StuckERC721Transferred(collection, tokenId, to);
    }

    function transferStuckERC1155(
        address collection,
        uint256 tokenId,
        uint256 amount,
        address to
    ) external onlyOwner nonReentrant {
        IERC1155(collection).safeTransferFrom(
            address(this),
            to,
            tokenId,
            amount,
            ""
        );

        emit StuckERC1155Transferred(collection, tokenId, amount, to);
    }
}
