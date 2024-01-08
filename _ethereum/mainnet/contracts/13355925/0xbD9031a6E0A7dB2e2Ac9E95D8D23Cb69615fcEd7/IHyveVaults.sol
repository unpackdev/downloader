//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IHyveVaults{

    function tierAmounts(uint256 tier) external returns(uint256);

    function stakeTimes(address holder,uint256 tier) external returns(uint256);

    function stakedAmounts(address holder,uint256 tier) external returns(uint256);      
  
}