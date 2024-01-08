// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface ILtoken {
    function mint(address to, uint256 token) external;

    function burn(address account, uint256 token) external;

    function balanceOf(address account) external view returns (uint256);

    function isNonFungibleToken() external pure returns (bool);

    function setTokenAmount(uint256 token, uint256 amount) external;

    function getTokenAmount(uint256 token) external view returns (uint256);
}
