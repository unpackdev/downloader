// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

interface IYieldTokenCompounding {
    function compound(
        uint8 _n,
        address _trancheAddress,
        bytes32 _balancerPoolId,
        uint256 _amount,
        uint256 _expectedYtOutput,
        uint256 _expectedBaseTokensSpent
    ) external returns (uint256, uint256);

    function approveTranchePTOnBalancer(address _trancheAddress) external;

    function checkTranchePTAllowanceOnBalancer(address _trancheAddress) external view returns (uint256);
}
