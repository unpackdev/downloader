// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/** @title Custom Interface for Curve VotingEscrow contract  */
interface IVotingEscrow {
    
    function balanceOf(address _account) external view returns (uint256);

    function create_lock(uint256 _value, uint256 _unlock_time) external returns (uint256);

    function locked__end(address _addr) external view returns (uint256);

}