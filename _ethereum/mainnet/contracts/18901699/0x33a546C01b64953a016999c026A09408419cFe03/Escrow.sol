// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Escrow {
    error AlreadyInitialized();
    error NotOwner();

    address private owner;

    /// @notice Initializes the Escrow with the sender of the transaction as owner.
    /// @dev This should be called in the same transaction as deploying the escrow, to prevent front running.
    function __Escrow_init() external {
        if (owner != address(0)) {
            revert AlreadyInitialized();
        }

        owner = msg.sender;
    }

    /// @notice Transfers a certain amount of ERC20 token to a given address. Can only be called by the owner.
    /// @param token The ERC20 contract address.
    /// @param to The address to recieve the tokens.
    /// @param amount The amount of ERC20 token to receive.
    function transfer(IERC20 token, address to, uint256 amount) external {
        if (msg.sender != owner) {
            revert NotOwner();
        }

        token.transfer(to, amount);
    }
}
