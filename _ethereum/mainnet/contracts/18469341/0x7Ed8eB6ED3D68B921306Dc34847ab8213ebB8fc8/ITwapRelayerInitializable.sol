pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9




interface ITwapRelayerInitializable {
    event Initialized(address _factory, address _delay, address _weth);

    function initialize() external;
}
