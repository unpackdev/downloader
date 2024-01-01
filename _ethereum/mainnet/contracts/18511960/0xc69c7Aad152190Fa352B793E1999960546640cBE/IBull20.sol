// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IRateProvider.sol";
import "./IToken.sol";
import "./Stage.sol";

interface IBull20 {
    // public

    function holders() external view returns (address[] memory);

    function enabled() external view returns (bool);

    function rateProvider() external view returns (IRateProvider);

    function stages() external view returns (Stage[] memory);

    function activeStage() external view returns (Stage memory);

    function totalRaised() external view returns (uint256);

    function presaleAmount(address _wallet) external view returns (uint256);

    // user

    function buy(uint256 amount, address token, uint256 msgValue, address msgSender) external payable;

    function disable() external;

    function enable() external;

    function setRateProvider(address rateProvider_) external;

    function addStage(uint256 priceUSD, uint256 expectedValue) external returns (Stage memory);

    function addStages(uint256[] memory prices, uint256[] memory expectedValues) external;

    function editStage(uint index, uint256 price, uint256 expectedValue) external returns (Stage memory);

    function deleteLastStage() external;

    function airdrop(address wallet, uint256 amount) external;

    function airdropMany(address[] memory wallets, uint256[] memory amounts) external;

    function withdraw(address holder) external payable;
}