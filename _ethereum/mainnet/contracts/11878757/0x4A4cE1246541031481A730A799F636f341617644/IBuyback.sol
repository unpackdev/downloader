// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IBuyback {
    event BuybackInitialized(uint256 _totalAmount, uint256 _singleAmount, uint256 _minTokensToHold);

    event SingleBuybackExecuted(address _sender, uint256 _senderRewardAmount, uint256 _buybackAmount);

    function initializerAddress() external view returns (address);

    function tokenAddress() external view returns (address);

    function uniswapRouterAddress() external view returns (address);

    function treasuryAddress() external view returns (address);

    function wethAddress() external view returns (address);

    function totalAmount() external view returns (uint256);

    function singleAmount() external view returns (uint256);

    function boughtBackAmount() external view returns (uint256);

    function lastBuyback() external view returns (uint256);

    function nextBuyback() external view returns (uint256);

    function minTokensForBuybackCall() external view returns (uint256);

    function buyback() external;
}
