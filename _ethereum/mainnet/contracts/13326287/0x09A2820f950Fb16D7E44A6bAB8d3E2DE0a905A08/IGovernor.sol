pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

interface IGovernor {

    function proposalThreshold() external view returns(uint);
    function quorumVotes() external view returns(uint);

}