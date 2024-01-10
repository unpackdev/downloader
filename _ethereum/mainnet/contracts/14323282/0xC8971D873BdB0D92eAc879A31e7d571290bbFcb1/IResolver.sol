// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./IKashiPair.sol";

interface IResolver {
    function updateExchangeRateForPairs(IKashiPair[] memory kashiPairs)
        external;

    function checker(IKashiPair[] memory kashiPairs)
        external
        view
        returns (bool canExec, bytes memory execPayload);
}
