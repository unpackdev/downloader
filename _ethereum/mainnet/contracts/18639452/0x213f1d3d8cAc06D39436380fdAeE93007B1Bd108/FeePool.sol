pragma solidity ^0.8.20;

interface FeePool {
    function feesAvailable(
        address account
    ) external view returns (uint256, uint256);

    function totalRewardsAvailable() external view returns (uint);

    function claimOnBehalf(address claimingForAddress) external returns (bool);
}