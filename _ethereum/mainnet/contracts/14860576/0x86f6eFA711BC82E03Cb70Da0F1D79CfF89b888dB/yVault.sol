// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface yVault {
    function deposit(uint256) external payable returns(uint);

    function withdraw(uint256, address) external returns(uint256);

    function approve(address,uint256 ) external returns (bool);

    function pricePerShare() external view returns (uint256);

    function balanceOf(address) external view returns(uint256);
}