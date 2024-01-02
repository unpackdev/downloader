// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IGuardian {
    function USDC() external view returns (address);

    function pricePerGuardian() external view returns (uint256);

    function totalBalanceOf(address) external view returns (uint256);

    function pendingReward(
        address account
    ) external view returns (uint256 reward, uint256 dividends);

    function split(address to, uint256 amount) external;

    function bond(address account, address feeToken, uint256 amount) external;

    function sellRewardForBond(address account, uint256 dividends) external;

    function claim() external;

    function updateRewardForObelisk(address account) external;
}
