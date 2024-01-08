// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ILazyInitCapableElement.sol";
import "./IPrestoUniV3.sol";

interface IInvestmentsManager is ILazyInitCapableElement {

    function ONE_HUNDRED() external pure returns(uint256);

    function refundETHReceiver() external view returns(bytes32 key, address receiverAddress);

    function executorRewardPercentage() external view returns(uint256);

    function prestoAddress() external view returns(address prestoAddress);

    function tokenFromETHToBurn() external view returns(address addr);

    function tokensFromETH() external view returns(address[] memory addresses);
    function setTokensFromETH(address[] calldata addresses) external returns(address[] memory oldAddresses);

    function swapFromETH(PrestoOperation[] calldata tokensFromETHData, PrestoOperation calldata tokenFromETHToBurnData, address executorRewardReceiver) external returns (uint256[] memory tokenAmounts, uint256 tokenFromETHToBurnAmount, uint256 executorReward);

    function lastSwapToETHBlock() external view returns (uint256);

    function swapToETHInterval() external view returns (uint256);

    function nextSwapToETHBlock() external view returns (uint256);

    function tokensToETH() external view returns(address[] memory addresses, uint256[] memory percentages);
    function setTokensToETH(address[] calldata addresses, uint256[] calldata percentages) external returns(address[] memory oldAddresses, uint256[] memory oldPercentages);

    function swapToETH(PrestoOperation[] calldata tokensToETHData, address executorRewardReceiver) external returns (uint256[] memory executorRewards, uint256[] memory ethAmounts);
}