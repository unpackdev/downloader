// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IDistributionStorage {
    function registered(address claimant) external view returns (uint256);
}
