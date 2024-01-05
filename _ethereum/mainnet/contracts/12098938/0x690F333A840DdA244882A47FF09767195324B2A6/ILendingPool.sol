// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface ILendingPool {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint256);
}
