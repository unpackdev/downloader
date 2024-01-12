// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import "./IFranchiserImmutableState.sol";
import "./IVotingToken.sol";

abstract contract FranchiserImmutableState is IFranchiserImmutableState {
    /// @inheritdoc IFranchiserImmutableState
    IVotingToken public immutable votingToken;

    constructor(IVotingToken votingToken_) {
        votingToken = votingToken_;
    }
}
