// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.0;

interface INest_3_MiningContract {

    function takeOutNest(address target) external; 

    function checkLatestMining() external view returns(uint256);

    function checkNestBalance() external view returns(uint256);
    
}