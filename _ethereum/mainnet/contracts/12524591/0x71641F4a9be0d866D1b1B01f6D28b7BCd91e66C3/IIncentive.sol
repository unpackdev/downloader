// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title incentive contract interface
/// @author Ring Protocol
/// @notice Called by Ring token contract when transferring with an incentivized address
/// @dev should be appointed as a Minter or Burner as needed
interface IIncentive {
    // ----------- Ring only state changing api -----------

    /// @notice apply incentives on transfer
    /// @param sender the sender address of the Ring
    /// @param receiver the receiver address of the Ring
    /// @param operator the operator (msg.sender) of the transfer
    /// @param amount the amount of Ring transferred
    function incentivize(
        address sender,
        address receiver,
        address operator,
        uint256 amount
    ) external;
}
