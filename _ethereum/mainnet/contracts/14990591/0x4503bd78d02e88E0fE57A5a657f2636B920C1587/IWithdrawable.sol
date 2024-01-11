//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

interface IWithdrawable {
    function pendingWithdrawal() external view returns (uint256);

    function withdraw(uint256 amount) external;

    function withdrawAll() external;
}
