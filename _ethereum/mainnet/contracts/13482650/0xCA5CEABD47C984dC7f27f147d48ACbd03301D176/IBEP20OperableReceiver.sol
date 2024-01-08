// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @title IBEP20OperableReceiver Interface
 * @dev Interface for any contract that wants to support transferAndCall or transferFromAndCall
 *  from BEP20Operable token contracts as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IBEP20OperableReceiver {

    /**
     * @notice Handle the receipt of BEP20Operable tokens
     * @dev Any BEP20Operable smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param sender address The address which are token transferred from
     * @param amount uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))` unless throwing
     */
    function onTransferReceived(address operator, address sender, uint256 amount, bytes calldata data) external returns (bytes4);
}
