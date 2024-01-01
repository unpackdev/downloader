// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IAirdropERC1155 {
    /**
     *  @notice Details of amount and recipient for airdropped token.
     *
     *  @param recipient The recipient of the tokens.
     *  @param tokenId ID of the ERC1155 token being airdropped.
     *  @param amount The quantity of tokens to airdrop.
     */
    struct AirdropContent {
        address recipient;
        uint256 amount;
    }

    /**
     *  @notice          Lets contract-owner send ERC1155 tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param tokenAddress    The contract address of the tokens to transfer.
     *  @param tokenOwner      The owner of the the tokens to transfer.
     *  @param contents        List containing recipient, tokenId to airdrop.
     */
    function airdropERC1155(
        address tokenAddress,
        address tokenOwner,
        AirdropContent[] calldata contents
    ) external;
}
