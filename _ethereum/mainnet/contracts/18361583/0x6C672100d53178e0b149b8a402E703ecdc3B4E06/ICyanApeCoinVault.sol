// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICyanApeCoinVault {
    struct DepositInfo {
        address recipient;
        uint256 amount;
    }

    function interestRates(uint256 poolId) external returns (uint256);

    function deposit(DepositInfo calldata depositInfo) external;

    function depositBatch(DepositInfo[] calldata deposits) external;

    function lend(
        address to,
        uint256 amount,
        uint256 poolId
    ) external;

    function pay(
        uint256 amount,
        uint256 profit,
        uint256 poolId
    ) external;

    function earn(uint256 profit) external;

    function getPoolInterestRates() external view returns (uint256[4] memory);
}
