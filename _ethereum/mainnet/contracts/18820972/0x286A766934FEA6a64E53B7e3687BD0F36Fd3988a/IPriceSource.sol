// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "./IPriceSourceReceiver.sol";

interface IPriceSource {
    function addRoundData(IPriceSourceReceiver _fraxOracle) external;
}
