// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

//interface for Prisma Fee Distribution.
interface IPrismaFeeDistributor {
    struct BoundedClaim {
        address token;
        uint256 claimFromWeek;
        uint256 claimUntilWeek;
    }
    
    function feeTokensLength() external view returns (uint);
    function claimable(address account, address[] calldata tokens) external view returns (uint256[] memory amounts);
    function claim(
        address account,
        address receiver,
        address[] calldata tokens
    ) external returns (uint256[] memory claimedAmounts);
    function claimWithBounds(
        address account,
        address receiver,
        BoundedClaim[] calldata claims
    ) external returns (uint256[] memory claimedAmounts);
}
