// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721.sol";
import "./IERC1155.sol";

/**
 * Helper contract to multi-send NFTs to multiple recipients
 */
contract MultiSendNFTs {

    struct SendContractData721 {
        address contractAddress;
        SendTokenData721[] tokenData; 
    }

    struct SendTokenData721 {
        address recipient;
        uint256 tokenId;
    }

    struct SendContractData1155 {
        address contractAddress;
        SendTokenData1155[] tokenData; 
    }

    struct SendTokenData1155 {
        address recipient;
        uint256 tokenId;
        uint256 amount;
    }

    function multiSend721(SendContractData721[] calldata data) public {
        // Check permissions first
        for (uint i = 0; i < data.length; i++) {
            SendContractData721 memory contractData = data[i];
            require(IERC721(contractData.contractAddress).isApprovedForAll(msg.sender, address(this)), "Contract needs to be approved to send");

            // Check ownership
            for (uint j = 0; j < contractData.tokenData.length; j++) {
                SendTokenData721 memory tokenData = contractData.tokenData[j];
                require(IERC721(contractData.contractAddress).ownerOf(tokenData.tokenId) == msg.sender, "Can only send tokens that you own");
            }
        }

        // Send tokens
        for (uint i = 0; i < data.length; i++) {
            SendContractData721 memory contractData = data[i];
            for (uint j = 0; j < contractData.tokenData.length; j++) {
                SendTokenData721 memory tokenData = contractData.tokenData[j];
                IERC721(contractData.contractAddress).safeTransferFrom(msg.sender, tokenData.recipient, tokenData.tokenId);
            }
        }
    }

    function multiSend1155(SendContractData1155[] calldata data) public {
        // Check permissions first
        for (uint i = 0; i < data.length; i++) {
            SendContractData1155 memory contractData = data[i];
            require(IERC1155(contractData.contractAddress).isApprovedForAll(msg.sender, address(this)), "Contract needs to be approved to send");

            // Check balances
            for (uint j = 0; j < contractData.tokenData.length; j++) {
                SendTokenData1155 memory tokenData = contractData.tokenData[j];
                require(IERC1155(contractData.contractAddress).balanceOf(msg.sender, tokenData.tokenId) >= tokenData.amount, "Not enough tokens");
            }
        }

        // Send tokens
        for (uint i = 0; i < data.length; i++) {
            SendContractData1155 memory contractData = data[i];
            for (uint j = 0; j < contractData.tokenData.length; j++) {
                SendTokenData1155 memory tokenData = contractData.tokenData[j];
                IERC1155(contractData.contractAddress).safeTransferFrom(msg.sender, tokenData.recipient, tokenData.tokenId, tokenData.amount, "");
            }
        }
    }

}
