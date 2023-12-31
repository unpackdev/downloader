// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {
    function transfer(
        address receipient,
        uint256 amount
    ) external returns (bool);

    function approve(address _spender, uint256 _amount) external;

    function balanceOf(address holder) external view returns (uint256);
}
