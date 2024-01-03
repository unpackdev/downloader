// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

/**
 * @dev Interface of the IXPGFKRecipient influenced by
 * ERC777TokensRecipient standard as defined in the EIP.
 *
 * IERC20 contracts should call this after _transfer
 */
interface IXPGFKRecipient {
    /**
     * @dev Called by an {IERC20} token contract whenever tokens are being
     * moved or created into a registered account (`to`).
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function onXPGFKReceived(
        address operator,
        address from,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);
}
