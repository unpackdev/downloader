// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IWithdraw {

    /*
        @notice Withdraw ERC20 from the smart contract.
        @dev Can be called only by the contract manager.
        @param token The address of the ERC20 token.
        @param to The receiver.
        @param amount The amount to be withdrawn.
    */
    function withdrawERC20(address token, address to, uint256 amount) external;

    /*
        @notice Withdraw ERC721 from the smart contract.
        @dev Can be called only by the contract manager.
            Only ERC721 tokens not associated with frames can be withdrawn.
        @param token The address of the ERC721 token.
        @param to The receiver.
        @param id The id of the token to be withdrawn.
    */
    function withdrawERC721(address to, address token, uint256 id) external;

    /*
        @notice Withdraw ERC1155 from the smart contract.
        @dev Can be called only by the contract manager.
            Only ERC721 tokens not associated with frames can be withdrawn.
        @param token The address of the ERC1155 token.
        @param to The receiver.
        @param id The id of the token to be withdrawn.
        @param amount The amount of tokens to be withdrawn.
    */
    function withdrawERC1155(address to, address token, uint256 id, uint256 amount) external;

    /**
        @notice emitted when ERC20 token is withdrawn.
        @param token The address of the ERC20 token.
        @param to The receiver.
        @param amount The amount to be withdrawn.
    */
    event WithdrawalErc20(address indexed token, address indexed to, uint256 amount);

    /**
        @notice emitted when an ERC721 or ERC1155 token is withdrawn.
        @param token The address of the NFT's smart contract.
        @param to The receiver.
        @param id The id of the token.
        @param amount The amount of transferred tokens. Note that for ERC721 it is always equal to 1.
    */
    event WithdrawalNft(address token, address to, uint256 id, uint256 amount);

}
