// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVoteStrategy {

    function snapshot(address target) external;
    function totalVotePower(address target, uint blockNo) external view returns(uint);
    function votePower(address target, uint blockNo, address account) external view returns(uint);
    function minPower(address target) external view returns(uint);
    function creationFee(address target) external view returns(uint);
    function minQuorum(address target) external view returns(uint);
    function voteDifferential(address target) external view returns(uint);
    function duration(address target) external view returns(uint64);
    function executionDelay(address target) external view returns(uint64);
}