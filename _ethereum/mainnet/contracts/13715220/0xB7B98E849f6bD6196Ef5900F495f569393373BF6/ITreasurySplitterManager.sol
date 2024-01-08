// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ILazyInitCapableElement.sol";

interface ITreasurySplitterManager is ILazyInitCapableElement {

    event Splitted(bytes32 indexed subDAO, address indexed receiver, uint256 amount);

    function ONE_HUNDRED() external pure returns(uint256);

    function lastSplitBlock() external view returns (uint256);

    function splitInterval() external view returns (uint256);

    function nextSplitBlock() external view returns (uint256);

    function executorRewardPercentage() external view returns(uint256);

    function flushExecutorRewardPercentage() external view returns(uint256);

    function receiversAndPercentages() external view returns (bytes32[] memory keys, address[] memory addresses, uint256[] memory percentages);

    function flushReceiver() external view returns(bytes32 key, address addr);

    function flushERC20Tokens(address[] calldata tokenAddresses, address executorRewardReceiver) external;

    function splitTreasury(address executorRewardReceiver) external;
}