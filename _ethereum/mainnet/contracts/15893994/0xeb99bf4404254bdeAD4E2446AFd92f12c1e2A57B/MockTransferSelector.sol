// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155.sol";
import "./SafeERC20.sol";
import "./ILooksRareAdapter.sol";

import "./console.sol";

contract MockTransferSelector {
    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    address public TRANSFER_MANAGER_ERC721;

    address public TRANSFER_MANAGER_ERC1155;

    constructor(address _transferManagerERC721, address _transferManagerERC1155)
    {
        TRANSFER_MANAGER_ERC721 = _transferManagerERC721;
        TRANSFER_MANAGER_ERC1155 = _transferManagerERC1155;
    }

    function checkTransferManagerForToken(address collection)
        external
        view
        returns (address transferManager)
    {
        if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)) {
            transferManager = TRANSFER_MANAGER_ERC721;
        } else if (
            IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)
        ) {
            transferManager = TRANSFER_MANAGER_ERC1155;
        }
        return transferManager;
    }
}
