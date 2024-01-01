// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

interface IChainlink {
    function latestAnswer(address base, address quote)
        external
        view
        returns (uint256 answer);
}
