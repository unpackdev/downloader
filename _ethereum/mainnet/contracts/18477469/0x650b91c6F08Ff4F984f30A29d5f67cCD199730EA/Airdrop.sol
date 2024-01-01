// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./IERC1155.sol";

contract Airdrop{
    function bulkDropERC721(address token, address[] memory recipients, uint256[] memory tokenIds) external {
        IERC721 erc721 = IERC721(token);
        for(uint256 i = 0; i < recipients.length; i++){
            erc721.safeTransferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }

    function bulkDropERC1155(address[] memory tokens, address[] memory recipients, uint256[] memory tokenIds, uint256[] memory amounts) external {
        
        for(uint256 i = 0; i < tokens.length; i++){
            IERC1155 erc1155 = IERC1155(tokens[i]);
            erc1155.safeTransferFrom(msg.sender, recipients[i], tokenIds[i], amounts[i], "");
        }
    }
}