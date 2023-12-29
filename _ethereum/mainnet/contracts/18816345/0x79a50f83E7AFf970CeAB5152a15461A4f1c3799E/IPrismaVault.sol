// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

//interface for the PrismaVault.
interface IPrismaVault {
    function unallocatedTotal() external view returns (uint256);

    function allocateNewEmissions(uint id) external returns (uint256);

    function transferAllocatedTokens(address receiver, uint256 amount) external returns (uint256);
    
    function claimableBoostDelegationFees(address claimant) external view returns (uint256 amount);

    function batchClaimRewards(
        address receiver,
        address boostDelegate,
        address[] calldata rewardContracts,
        uint256 maxFeePct
    ) external returns (bool);
}
