//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./ERC1155Receiver.sol";
import "./CommonConstants.sol";

abstract contract ERC1155TokenReceiver is ERC1155Receiver, CommonConstants {

    /**
     * ERC1155Receiver hook for single transfer.
     * @dev Reverts if the caller is not the whitelisted NFT contract.
     */
    function onERC1155Received(
        address, /*operator*/
        address, /*from _msgSender*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        return ERC1155_ACCEPTED;
    }

    /**
     * ERC1155Receiver hook for batch transfer.
     * @dev Reverts if the caller is not the whitelisted NFT contract.
     */
    function onERC1155BatchReceived(
        address, /*operator*/
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*value*/
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        return ERC1155_BATCH_ACCEPTED;
    }
}