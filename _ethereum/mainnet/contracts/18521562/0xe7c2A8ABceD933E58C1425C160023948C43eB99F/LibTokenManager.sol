// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC721.sol";
import "./IERC1155.sol";

import "./LibAppStorage.sol";

library LibTokenManager {
    event TokenSent(address player, address collection, uint256 tokenId);

    /**
     * @notice Sends a token to a player.
     * @dev called by a CCIP message send from manager on Polygon.
     * @dev Checks if the token is of type ERC1155 or ERC721 and performs the transfer accordingly.
     * @param payload Payload sent by the manager.
     */
    function sendToken(bytes memory payload) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        (address player, address collection, uint256 tokenId) = abi.decode(payload, (address, address, uint256));

        IERC165 tokenContract = IERC165(collection);
        bool isERC1155 = tokenContract.supportsInterface(0xd9b67a26);

        if (isERC1155) {
            IERC1155(collection).safeTransferFrom(s.storageAddress, player, tokenId, 1, "");
        } else {
            IERC721(collection).safeTransferFrom(s.storageAddress, player, tokenId);
        }

        emit TokenSent(player, collection, tokenId);
    }
}
