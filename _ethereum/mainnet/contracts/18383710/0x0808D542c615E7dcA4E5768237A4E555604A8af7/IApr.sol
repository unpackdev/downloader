// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IApr {
    function apr(
        uint256 _rate,
        uint256 _priceOfRewards,
        uint256 _priceOfDeposits
    ) external view returns (uint256);

    function rewardRates(
        uint256 _pid
    ) external view returns (address[] calldata, uint256[] calldata);
}
