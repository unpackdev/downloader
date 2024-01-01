pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9




interface ITwapFactoryGovernorInitializable {
    event Initialized(address _factory);

    function initialize(address _factory) external;
}
