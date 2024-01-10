pragma solidity 0.8.11;

import "./ERC1155.sol";
import "./ERC721.sol";

contract BatchTransfer {

    function batchTransferERC721(
        address token,
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) external {
         for (uint256 i = 0; i < recipients.length; ++i)
            ERC721(token).safeTransferFrom(msg.sender, recipients[i], tokenIds[i]);
    }

    function batchTransferERC1155(
        address token,
        address[] calldata recipients,
        uint256[][] calldata tokenIds,
        uint256[][] calldata amounts
    ) external {
        for (uint256 i = 0; i < recipients.length; ++i){
            ERC1155(token).safeBatchTransferFrom(
                msg.sender,
                recipients[i],
                tokenIds[i],
                amounts[i],
                ""
            );
        }
            
    }
}