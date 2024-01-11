/// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

interface IFeeDistributor {
    function claim() external;
    function tokens() external view returns (address[] memory);
}