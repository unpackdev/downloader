// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DistributionContract.sol";

contract MahaTeamDistribution is DistributionContract {
    // 3 month cliff/linear release
    constructor(address token)
        DistributionContract(
            token,
            1639785600, // Dec 18th 2021 00:00 UTC
            365 * 3 // 3 years
        )
    {}
}
