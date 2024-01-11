// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IGaugeProxy {
    function collect() external;
    function deposit() external;
    function distribute() external;
    function vote(address[] memory, uint256[] memory) external;
}