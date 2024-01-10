// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface IPilgrimTreasury {
    function withdraw(address _to, uint256 _amount) external;
}
