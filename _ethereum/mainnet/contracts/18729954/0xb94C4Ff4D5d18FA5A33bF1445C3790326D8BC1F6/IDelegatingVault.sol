// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "DataTypes.sol";

interface IDelegatingVault {
    function delegateVote(address _delegate, uint256 _amount) external;

    function undelegateVote(address _delegate, uint256 _amount) external;

    function changeDelegate(
        address _oldDelegate,
        address _newDelegate,
        uint256 _amount
    ) external;

    function getDelegations(
        address account
    ) external view returns (DataTypes.Delegation[] memory delegations);

    event VotesDelegated(address delegator, address delegate, uint amount);
    event VotesUndelegated(address delegator, address delegate, uint amount);
}
