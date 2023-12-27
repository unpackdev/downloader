// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPrismaFeeDistributor {
    function accountClaimWeek(
        address account,
        address token
    ) external view returns (uint week);
    function claimable(
        address account,
        address[] calldata tokens
    ) external view returns (uint256[] memory amounts);
    function getWeek() external view returns (uint week);
    function claim(
        address account,
        address receiver,
        address[] calldata tokens
    ) external returns (uint256[] memory claimedAmounts);
}
