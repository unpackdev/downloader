// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolDerivedState {
    function expectedRestakeRevenue(uint256 amount) external view returns (uint256);
    function expectedRevenue(address _account) external view returns (uint256);
}