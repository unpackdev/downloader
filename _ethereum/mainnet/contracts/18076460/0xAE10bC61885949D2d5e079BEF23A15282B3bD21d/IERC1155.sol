// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC1155 {

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the
            `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account.
            MUST revert if `_to` is the zero address.
            MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
            MUST revert on any other error.
            MUST emit the `TransferSingle` event to reflect the balance change.
            After the above conditions are met, this function MUST check if `_to` is a smart contract.
            If so, it MUST call `onERC1155Received` on `_to` and act appropriately.
        @param _from Source address.
        @param _to Target address.
        @param _id ID of the token type.
        @param _value Transfer amount.
        @param _data Additional data with no specified format,
            MUST be sent unaltered in call to `onERC1155Received` on `_to`.
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
        @notice Get the balance of an account's tokens.
        @param _owner The address of the token holder.
        @param _id ID of the token.
        @return The _owner's balance of the token type requested.
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}
