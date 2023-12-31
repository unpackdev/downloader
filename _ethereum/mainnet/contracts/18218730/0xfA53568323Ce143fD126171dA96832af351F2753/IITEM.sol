// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IITEM {
    function burn(address _account, uint256 _id, uint256 _amount) external;

    function balanceOf(
        address _account,
        uint256 _id
    ) external view returns (uint256);
}
