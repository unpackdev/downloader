// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IDistributionLogic {
    function version() external returns (uint256);

    function distribute(address tributary, uint256 contribution) external;

    function claim(address claimant) external;

    function claimable(address claimant) external view returns (uint256);

    function increaseAwards(address member, uint256 amount) external;
}
