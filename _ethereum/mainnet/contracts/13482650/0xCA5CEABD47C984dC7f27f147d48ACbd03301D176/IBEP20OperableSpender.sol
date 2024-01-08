// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @title IBEP20OperableSpender Interface
 * @dev Interface for any contract that wants to support approveAndCall
 *  from BEP20Operable token contracts as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IBEP20OperableSpender {

    /**
     * @notice Handle the approval of BEP20Operable tokens
     * @dev Any BEP20Operable smart contract calls this function on the recipient
     * after an `approve`. This function MAY throw to revert and reject the
     * approval. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param sender address The address which called `approveAndCall` function
     * @param amount uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))` unless throwing
     */
    function onApprovalReceived(address sender, uint256 amount, bytes calldata data) external returns (bytes4);
}
