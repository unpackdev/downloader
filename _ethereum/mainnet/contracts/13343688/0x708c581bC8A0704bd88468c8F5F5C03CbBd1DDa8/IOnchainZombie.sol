// contracts/IOnchainZombie.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOnchainZombie {
    function claimMouse(address _claimer) external;
    function claimMice(address _claimer, uint _num) external;
}