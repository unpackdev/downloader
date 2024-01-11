/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

interface IComptroller {
    function enterMarkets(address[] memory cTokens) external returns (uint256[] memory);

    function claimComp(address holder) external;

    function claimComp(address holder, address[] memory) external;

    function getAssetsIn(address account) external view returns (address[] memory);
}
