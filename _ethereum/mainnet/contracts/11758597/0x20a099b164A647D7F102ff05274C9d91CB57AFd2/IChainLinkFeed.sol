// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.6;

interface IChainLinkFeed {
    function latestAnswer() external view returns (int256);
}