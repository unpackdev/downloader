// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.14;

import "./StakingPermit.sol";

contract FocusStaking is StakingPermit {
    constructor(address _underlyingToken)
        StakingPermit("Staked Focus", "stFOTO", _underlyingToken)
    {}
}
