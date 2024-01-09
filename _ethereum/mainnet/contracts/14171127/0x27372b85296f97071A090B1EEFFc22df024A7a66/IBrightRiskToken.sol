// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IBrightRiskToken {
    struct DepositorInfo {
        uint256 depositAmount;
        bool readyToStake;
        uint256 minting;
    }

    function getBase() external view returns (address);

    function getPriceFeed() external view returns (address);

    function countPositions() external view returns (uint256);

    function listPositions(uint256 offset, uint256 limit) external view returns (address[] memory);

    function deposit(uint256 _maxAmount) external;

    function depositInternal(uint256 _amount) external;
}
