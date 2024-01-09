// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStrongService {
    function naasRequestingFeeInWei() external view returns (uint256);
    function naasStrongFeeInWei() external view returns (uint256);
    function recurringNaaSFeeInWei() external view returns (uint256);

    function requestingFeeInWei() external view returns (uint256);
    function strongFeeInWei() external view returns (uint256);
    function recurringFeeInWei() external view returns (uint256);

    function claimingFeeNumerator() external view returns (uint256);
    function claimingFeeDenominator() external view returns (uint256);

    function getNodeId(address entity, uint128 nodeId) external view returns (bytes memory);
    function entityNodeIsBYON(bytes memory id) external view returns (bool);

    function getRewardByBlock(address entity, uint128 nodeId, uint256 blockNumber) external view returns (uint256);
    function getReward(address entity, uint128 nodeId) external view returns (uint256);

    function requestAccess(bool isNaaS) external payable;
    function claim(uint128 nodeId, uint256 blockNumber, bool toStrongPool) external payable returns (bool);
    function payFee(uint128 nodeId) external payable;
    function payAll(uint256 nodeCount) external payable;
}