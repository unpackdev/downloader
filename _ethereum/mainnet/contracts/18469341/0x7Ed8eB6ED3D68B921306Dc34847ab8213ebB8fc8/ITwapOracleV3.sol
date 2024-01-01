pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



import "./ITwapOracle.sol";

interface ITwapOracleV3 is ITwapOracle {
    event TwapIntervalSet(uint32 interval);

    function setTwapInterval(uint32 _interval) external;
}
