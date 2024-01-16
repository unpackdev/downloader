// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IBlindAuctionInfo {
    function getUsersCountWillReceiveAirdrop() external view returns (uint256);

    function getMaxWinnersCount() external view returns (uint256);

    function getFinalPrice() external view returns (uint256);

    function getAuctionState() external view returns (uint8);

    function getSigner() external view returns (address);
}
