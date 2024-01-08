// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IComptroller {
    function oracle() external view returns (address);
    function getAssetsIn(address account) external view returns (address[] memory);
    function isMarketListed(address cTokenAddress) external view returns (bool);
}
