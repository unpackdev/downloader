//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract VaultEvent {
    /// @dev event on set claimer
    /// @param newClaimer new claimer address
    event SetNewClaimer(address newClaimer);

    /// @dev event on allocate amount
    ///@param round  it is the period unit can claim once
    ///@param amount total claimable amount
    event AllocatedAmount(uint256 round, uint256 amount);

    /// @dev event on add whitelist
    ///@param round  it is the period unit can claim once
    ///@param users people who can claim in that round
    event AddedWhitelist(uint256 round, address[] users);

    /// @dev event on start round
    ///@param round  it is the period unit can claim once
    event StartedRound(uint256 round);

    /// @dev event on start
    event Started();

    /// @dev event on claim
    ///@param caller  claimer
    ///@param amount  the claimed amount of caller
    ///@param totalClaimedAmount  total claimed amount
    event Claimed(
        address indexed caller,
        uint256 amount,
        uint256 totalClaimedAmount
    );

    /// @dev event on withdraw
    ///@param caller  owner
    ///@param amount  the withdrawable amount of owner
    event Withdrawal(address indexed caller, uint256 amount);
}
