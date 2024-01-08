// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ITangoRouter { 
    function withdraw(address _token,uint256 _amount) external;
    function invest(address _token, uint256 _amount) external;
}