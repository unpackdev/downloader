// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IERC721.sol";
import "./IERC1155.sol";

contract BulkSender2 {
    function batchTransferERC721(
        address erc721Address,
        address[] memory recipients,
        uint256[] memory tokenIds
    ) external {
        require(recipients.length == tokenIds.length, "Recipients and tokenIds arrays should have the same length");

        IERC721 erc721 = IERC721(erc721Address);

        for (uint256 i = 0; i < recipients.length;) {
            erc721.transferFrom(msg.sender, recipients[i], tokenIds[i]);

            unchecked {
                i++;
            }
        }
    }

    function batchTransferERC1155(
        address erc1155Address,
        address[] memory recipients,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        require(recipients.length == tokenIds.length, "Recipients and tokenIds arrays should have the same length");
        require(tokenIds.length == amounts.length, "TokenIds and amounts arrays should have the same length");

        IERC1155 erc1155 = IERC1155(erc1155Address);

        for (uint256 i = 0; i < recipients.length;) {
            erc1155.safeTransferFrom(msg.sender, recipients[i], tokenIds[i], amounts[i], data);

            unchecked {
                i++;
            }
        }
    }
}
