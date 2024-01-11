//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

import "./IERC721.sol";
import "./IERC1155.sol";

error NoRecipients();
error LengthMismatch();

contract NFTAirDrop {
    /**
     * @notice msg.sender should have {setApprovalForAll} true of the ERC721 in {tokenAddress}
     * @dev Airdrops ERC721 tokens with {tokenIds} to {recipients} addresses
     * @param erc721 address of ERC721
     * @param recipients recipients addresses
     * @param tokenIds ERC721 token IDs
     */
    function multiSendERC721(
        IERC721 erc721,
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) external {
        if (recipients.length == 0) {
            revert NoRecipients();
        }

        if (recipients.length != tokenIds.length) {
            revert LengthMismatch();
        }

        address[] memory _recipients = recipients;
        uint256[] memory _tokenIds = tokenIds;
        uint256 length = _recipients.length;

        for (uint256 i; i < length; ) {
            erc721.safeTransferFrom(msg.sender, _recipients[i], _tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice msg.sender should have {setApprovalForAll} true of the ERC1155 in {tokenAddress}
     * @dev Airdrops ERC1155 tokens with {tokenIds} of {amounts} to {recipients} addresses
     * @param erc1155 ERC1155 token address
     * @param recipients recipients addresses
     * @param tokenIds ERC1155 token IDs
     * @param amounts amounts to send
     */
    function multiSendERC1155(
        IERC1155 erc1155,
        address[] calldata recipients,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external {
        if (recipients.length == 0) {
            revert NoRecipients();
        }
        if (recipients.length != tokenIds.length || recipients.length != amounts.length) {
            revert LengthMismatch();
        }

        address[] memory _recipients = recipients;
        uint256[] memory _tokenIds = tokenIds;
        uint256[] memory _amounts = amounts;
        uint256 length = _recipients.length;

        for (uint256 i; i < length; ) {
            erc1155.safeTransferFrom(msg.sender, _recipients[i], _tokenIds[i], _amounts[i], "");

            unchecked {
                ++i;
            }
        }
    }
}
