// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./APMorgan.sol";
import "./APMorganMinter.sol";

contract APMorganDeployable is APMorgan {
    constructor() APMorgan(false) {}
}

contract APMorganTestNet is APMorganDeployable {
    using SettableCountersUpgradeable for SettableCountersUpgradeable.Counter;

    constructor() APMorganDeployable() {}

    /// @notice Helper function for testnet deployment allowing for multiple vrf from a single address tests
    function unsetClaimed(address claimooor) external {
        claimed[claimooor] = false;
    }
}
