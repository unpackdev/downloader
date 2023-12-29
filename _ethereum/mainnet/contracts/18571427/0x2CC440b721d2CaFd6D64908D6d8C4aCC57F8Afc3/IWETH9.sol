// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IWETH9 {

    function deposit() external payable ;
    function withdraw(uint wad) external payable;
    function totalSupply() external returns (uint);  
    function approve(address guy, uint wad) external returns (bool);

}