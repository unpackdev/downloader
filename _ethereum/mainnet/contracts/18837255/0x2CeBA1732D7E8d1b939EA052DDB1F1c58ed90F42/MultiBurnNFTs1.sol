// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./IERC721CreatorCore.sol";

/**
 * @title MultiBurnNFTs
 * @dev Helper contract to burn multiple NFTs safely and efficiently.
 *      Uses OpenZeppelin's libraries for additional safety checks.
 */
contract MultiBurnNFTs is ReentrancyGuard {

    struct BurnContractData721 {
        address contractAddress;
        uint256[] tokenIds; 
    }

    /**
     * @notice Burns multiple ERC721 tokens from different contracts in a single transaction.
     * @param data An array of BurnContractData721 representing contract addresses and their respective token IDs to be burned.
     */

    function multiBurn721(BurnContractData721[] calldata data) external nonReentrant {
        // Check approvals and ownership first
        for (uint256 i = 0; i < data.length; i++) {
            BurnContractData721 memory contractData = data[i];
            IERC721 token = IERC721(contractData.contractAddress);

            require(token.isApprovedForAll(msg.sender, address(this)), "MultiBurnNFTs: Contract not approved");

            for (uint256 j = 0; j < contractData.tokenIds.length; j++) {
                uint256 tokenId = contractData.tokenIds[j];
                require(token.ownerOf(tokenId) == msg.sender, "MultiBurnNFTs: Not token owner");
            }
        }

        // Perform the burn
        for (uint256 i = 0; i < data.length; i++) {
            BurnContractData721 memory contractData = data[i];
            IERC721CreatorCore tokenContract = IERC721CreatorCore(contractData.contractAddress);

            for (uint256 j = 0; j < contractData.tokenIds.length; j++) {
                uint256 tokenId = contractData.tokenIds[j];                
                tokenContract.burn(tokenId);
            }
        }
    }
}