// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./IResolver.sol";

contract KashiExchangeRateResolver is IResolver {
    function updateExchangeRateForPairs(IKashiPair[] memory kashiPairs)
        external
    {
        for (uint256 i; i < kashiPairs.length; i++) {
            if (address(kashiPairs[i]) != address(0)) {
                kashiPairs[i].updateExchangeRate();
            }
        }
    }

    function checker(IKashiPair[] memory kashiPairs)
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        IKashiPair[] memory pairsToUpdate = new IKashiPair[](kashiPairs.length);

        for (uint256 i; i < kashiPairs.length; i++) {
            IOracle oracle = kashiPairs[i].oracle();
            bytes memory oracleData = kashiPairs[i].oracleData();
            uint256 lastExchangeRate = kashiPairs[i].exchangeRate();
            (bool updated, uint256 rate) = oracle.peek(oracleData);
            if (updated) {
                uint256 deviation = ((
                    lastExchangeRate > rate
                        ? lastExchangeRate - rate
                        : rate - lastExchangeRate
                ) * 100) / lastExchangeRate;
                if (deviation > 20) {
                    pairsToUpdate[i] = kashiPairs[i];
                    canExec = true;
                }
            }
        }

        if (canExec) {
            execPayload = abi.encodeWithSignature(
                "updateExchangeRateForPairs(address[])",
                pairsToUpdate
            );
        }
    }
}
