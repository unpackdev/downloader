// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IHarvest
{
    event Thanks(address indexed donator, uint256 donation);
    event HarvestCollected();

    /// the function of collecting tokens that got accidentally
    /// or specifically into a smart contract and were not recorded
    /// in storage
    /// NOTE: this function does not take user's funds from the contract,
    /// but will withdraw those funds that are considered to be
    /// donation funds!
    function collect(address token) external returns (bool);
}
