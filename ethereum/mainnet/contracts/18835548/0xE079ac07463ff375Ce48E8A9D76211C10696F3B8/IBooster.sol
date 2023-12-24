// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IBooster {
    function withdraw(address _gauge, uint256 _amount) external;
}
