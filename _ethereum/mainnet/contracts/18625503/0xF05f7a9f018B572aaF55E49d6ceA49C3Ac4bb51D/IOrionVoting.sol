// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IStaking.sol";

interface IOrionVoting is IStaking
{

    //admin
    function setSmart(address addr, bool bUse) external;
    function setRewards(uint64 rewards, uint64 duration) external;
    function addPool(address pool) external;
    function deletePool(address pool) external;


    //user
    function vote(address pool, uint256 amount) external;
    function voteArr(address[] calldata pools, uint256[] calldata amounts) external;
    function unvote(address pool, uint256 amount) external;
    function unvoteAll(address account) external;

    //smart
    function claimReward(address pool, address to, uint256 amount) external;

    //vew
    function countPool() external view returns (uint256);//number of pools
    function poolList(uint256) external view returns (address);//list of pools
    function poolIndex(address pool) external view returns (uint256);//whether there is a pool in the list (index numbers starting from 1)
    function users(address user) external view returns (uint256);//user votes across all pools
    function usersPool(address user,address pool) external view returns (uint256);//user votes by pool
    function smarts(address smart) external view returns (bool);//white list of trusted farm contracts

    function veORN() external view returns (address);
    function ORN() external view returns (address);

    function havePool(address account) external view returns (bool);



}
