//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRaiderGold {
    function adminMint(address _account, uint256 _amount) external payable;
    function adminBurn(address _account, uint256 _amount) external;
    function balanceOf(address account) external view returns (uint256);
}