// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC165.sol";
import "./ITransferManagerSelector.sol";
import "./TransferManagerSelectorStorage.sol";

contract TransferManagerSelector is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ITransferManagerSelector,
    TransferManagerSelectorStorage
{
    function initialize(
        address _transferManagerErc721,
        address _transferManagerErc1155
    ) external initializer {
        __Ownable_init();
        _interfaceIdErc721 = 0x80ac58cd;
        _interfaceIdErc1155 = 0xd9b67a26;
        transferManagerErc721 = _transferManagerErc721;
        transferManagerErc1155 = _transferManagerErc1155;
    }

    // For UUPSUpgradeable
    function _authorizeUpgrade(address) internal view override {
        require(_msgSender() == owner(), "TMSelector: caller is not owner");
    }

    function setCollectionTransferManager(
        address collection,
        address transferManager
    ) external override onlyOwner {
        transferManagerByCollection[collection] = transferManager;
        emit CollectionTransferManagerSet(collection, transferManager);
    }

    function unSetCollectionTransferManager(address collection)
        external
        override
        onlyOwner
    {
        delete transferManagerByCollection[collection];
        emit CollectionTransferManagerUnSet(collection);
    }

    function getTransferManager(address collection)
        external
        view
        override
        returns (address)
    {
        address transferManager = transferManagerByCollection[collection];
        if (transferManager != address(0)) {
            return transferManager;
        }
        if (IERC165(collection).supportsInterface(_interfaceIdErc721)) {
            return transferManagerErc721;
        }
        if (IERC165(collection).supportsInterface(_interfaceIdErc1155)) {
            return transferManagerErc1155;
        }
        return transferManager;
    }
}
