// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title INeatToken
 * @author NeatFi
 * @notice Interface to the {NeatToken} contract.
 */
interface INeatToken {
    /**
     * @notice Transfers tokens on behalf of the holder.
     * @param sender - The address of the token holder.
     * @param recipient - The address of the token recipient.
     * @param amount - The amount of tokens.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Holder transfers tokens.
     * @param recipient - The address of the token recipient.
     * @param amount - The amount of tokens.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @notice Returns the balance of Neats for an account.
     * @param account - The account in question.
     */
    function balanceOf(address account) external returns (uint256);
}
