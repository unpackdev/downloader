// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface ICryptoTittyV1 {

    function tittyIndexToAddress(uint256 punkIndex) external returns (address);
    function tittyOfferedForSale(uint256 punkIndex) external returns (bool, uint256, address, uint256, address);
    function buyTitty(uint punkIndex) external payable;
    function transferTitty(address to, uint punkIndex) external;

}