// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ITaskTreasury {
    function withdrawFunds(
        address payable _receiver,
        address _token,
        uint256 _amount
    ) external;
}
