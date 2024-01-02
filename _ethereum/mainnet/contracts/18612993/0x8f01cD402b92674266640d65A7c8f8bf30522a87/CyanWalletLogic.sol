// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ICyanConduit.sol";
import "./AddressProvider.sol";
import "./ICryptoPunk.sol";
import "./IWallet.sol";
import "./ICyanPeerPlan.sol";
import "./PaymentPlanTypes.sol";

library CyanWalletLogic {
    AddressProvider private constant addressProvider = AddressProvider(0xCF9A19D879769aDaE5e4f31503AAECDa82568E55);

    /**
     * @notice Allows operators to transfer out non locked tokens.
     *     Note: Can only transfer if token is not locked.
     * @param cyanWalletAddress Cyan Wallet address
     * @param to Receiver address
     * @param item Transferring item
     */
    function transferNonLockedItem(
        address cyanWalletAddress,
        address to,
        Item calldata item
    ) external {
        _transferNonLockedItem(cyanWalletAddress, to, item.contractAddress, item.tokenId, item.amount, item.itemType);
    }

    /**
     * @notice Allows operators to transfer out non locked tokens.
     *     Note: Can only transfer if token is not locked.
     * @param cyanWalletAddress Cyan Wallet address
     * @param to Receiver address
     * @param item Transferring item
     */
    function transferNonLockedItem(
        address cyanWalletAddress,
        address to,
        ICyanPeerPlan.Item calldata item
    ) external {
        _transferNonLockedItem(cyanWalletAddress, to, item.contractAddress, item.tokenId, item.amount, item.itemType);
    }

    function _transferNonLockedItem(
        address cyanWalletAddress,
        address to,
        address collection,
        uint256 tokenId,
        uint256 amount,
        uint8 itemType
    ) private {
        IWallet wallet = IWallet(cyanWalletAddress);
        if (itemType == 1) {
            // ERC721
            wallet.executeModule(
                abi.encodeWithSelector(IWallet.transferNonLockedERC721.selector, collection, tokenId, to)
            );
        } else if (itemType == 2) {
            // ERC1155
            wallet.executeModule(
                abi.encodeWithSelector(IWallet.transferNonLockedERC1155.selector, collection, tokenId, amount, to)
            );
        } else if (itemType == 3) {
            // CryptoPunks
            wallet.executeModule(abi.encodeWithSelector(IWallet.transferNonLockedCryptoPunk.selector, tokenId, to));
        } else {
            revert InvalidItem();
        }
    }

    /**
     * @notice Transfers token to CyanWallet and locks it
     * @param from From address
     * @param cyanWalletAddress Cyan Wallet address
     * @param item Transferring item
     */
    function transferItemAndLock(
        address from,
        address cyanWalletAddress,
        Item calldata item
    ) external {
        _transferItemAndLock(from, cyanWalletAddress, item.contractAddress, item.tokenId, item.amount, item.itemType);
    }

    /**
     * @notice Transfers token to CyanWallet and locks it
     * @param from From address
     * @param cyanWalletAddress Cyan Wallet address
     * @param item Transferring item
     */
    function transferItemAndLock(
        address from,
        address cyanWalletAddress,
        ICyanPeerPlan.Item calldata item
    ) external {
        _transferItemAndLock(from, cyanWalletAddress, item.contractAddress, item.tokenId, item.amount, item.itemType);
    }

    function _transferItemAndLock(
        address from,
        address cyanWalletAddress,
        address collection,
        uint256 tokenId,
        uint256 amount,
        uint8 itemType
    ) private {
        if (itemType == 3) {
            // CryptoPunks
            ICryptoPunk cryptoPunkContract = ICryptoPunk(collection);
            cryptoPunkContract.buyPunk{ value: 0 }(tokenId);
            cryptoPunkContract.transferPunk(cyanWalletAddress, tokenId);
        } else {
            ICyanConduit conduit = ICyanConduit(addressProvider.addresses("CYAN_CONDUIT"));
            if (itemType == 1) {
                conduit.transferERC721(from, cyanWalletAddress, collection, tokenId);
            } else if (itemType == 2) {
                conduit.transferERC1155(from, cyanWalletAddress, collection, tokenId, amount);
            } else {
                revert InvalidItem();
            }
        }

        _setLockState(cyanWalletAddress, collection, tokenId, amount, itemType, true);
    }

    /**
     * @notice Update locking status of a token in Cyan Wallet
     * @param cyanWalletAddress Cyan Wallet address
     * @param item Locking/unlocking item
     * @param state Token will be locked if true
     */
    function setLockState(
        address cyanWalletAddress,
        Item calldata item,
        bool state
    ) public {
        _setLockState(cyanWalletAddress, item.contractAddress, item.tokenId, item.amount, item.itemType, state);
    }

    /**
     * @notice Update locking status of a token in Cyan Wallet
     * @param cyanWalletAddress Cyan Wallet address
     * @param item Locking/unlocking item
     * @param state Token will be locked if true
     */
    function setLockState(
        address cyanWalletAddress,
        ICyanPeerPlan.Item calldata item,
        bool state
    ) public {
        _setLockState(cyanWalletAddress, item.contractAddress, item.tokenId, item.amount, item.itemType, state);
    }

    function _setLockState(
        address cyanWalletAddress,
        address collection,
        uint256 tokenId,
        uint256 amount,
        uint8 itemType,
        bool state
    ) private {
        IWallet wallet = IWallet(cyanWalletAddress);
        if (itemType == 1) {
            // ERC721
            wallet.executeModule(
                abi.encodeWithSelector(IWallet.setLockedERC721Token.selector, collection, tokenId, state)
            );
        } else if (itemType == 2) {
            // ERC1155
            wallet.executeModule(
                abi.encodeWithSelector(
                    state ? IWallet.increaseLockedERC1155Token.selector : IWallet.decreaseLockedERC1155Token.selector,
                    collection,
                    tokenId,
                    amount
                )
            );
        } else if (itemType == 3) {
            // CryptoPunks
            wallet.executeModule(abi.encodeWithSelector(IWallet.setLockedCryptoPunk.selector, tokenId, state));
        } else {
            revert InvalidItem();
        }
    }

    /**
     * @notice Triggers Cyan Wallet's autoPay method
     * @param cyanWalletAddress Cyan Wallet address
     * @param planId Payment plan ID
     * @param amount Pay amount for the plan
     * @param autoRepayStatus Auto repayment status
     */
    function executeAutoPay(
        address cyanWalletAddress,
        uint256 planId,
        uint256 amount,
        uint8 autoRepayStatus
    ) external {
        IWallet(cyanWalletAddress).executeModule(
            abi.encodeWithSelector(IWallet.autoPay.selector, planId, amount, autoRepayStatus)
        );
    }
}
