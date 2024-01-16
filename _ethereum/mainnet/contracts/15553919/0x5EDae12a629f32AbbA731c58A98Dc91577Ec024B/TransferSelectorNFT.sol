// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC165.sol";

import "./TheTransFerSelector.sol";

contract TransferSelectorNFT is TheTransferSelector, Ownable {
    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    // 721 protocol address
    address public immutable TRANSFER_MANAGER_ERC721;

    //1155 transfer protocol address
    address public immutable TRANSFER_MANAGER_ERC1155;

    // manager address mapping
    mapping(address => address) public transferManagerSelectorForCollection;

    event CollectionTransferManagerAdded(address indexed collection, address indexed transferManager);
    event CollectionTransferManagerRemoved(address indexed collection);

    //  initialize the transfer manager addresses of 1155 and 721
    constructor(address _transferManagerERC721, address _transferManagerERC1155) {
        TRANSFER_MANAGER_ERC721 = _transferManagerERC721;
        TRANSFER_MANAGER_ERC1155 = _transferManagerERC1155;
    }

    //
    // tion addCollectionTransferManager
    //  @Description: Add a designated transfer contract for a collection
    //  @param address
    //  @param address
    //  @return external
    //
    function addCollectionTransferManager(address collection, address transferManager) external onlyOwner {
        require(collection != address(0), " Collection cannot be null address");
        require(transferManager != address(0), "TransferManager cannot be null address");
        // Confirm collection is not null and transfer manager is not null

        transferManagerSelectorForCollection[collection] = transferManager;

        emit CollectionTransferManagerAdded(collection, transferManager);
    }

    //
    // tion removeCollectionTransferManager
    //  @Description: Delete a collection transfer contract
    //  @param address
    //  @return external
    //
    function removeCollectionTransferManager(address collection) external onlyOwner {
        require(
            transferManagerSelectorForCollection[collection] != address(0),
            "Collection has no transfer manager"
        );

        transferManagerSelectorForCollection[collection] = address(0);

        emit CollectionTransferManagerRemoved(collection);
    }

    // Confrim the transfer manager for a collection
    function checkTransferManagerForToken(address collection) external view override returns (address transferManager) {
        // If there is designated manager contract, then return
        transferManager = transferManagerSelectorForCollection[collection];

        // If there is not designated manager contract, decide using collection's API
        if (transferManager == address(0)) {
            if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)) {
                transferManager = TRANSFER_MANAGER_ERC721;
            } else if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)) {
                transferManager = TRANSFER_MANAGER_ERC1155;
            }
        }

        return transferManager;
    }
}
