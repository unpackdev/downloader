// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IYabaiGoblinMinter {
    event SetLimit(uint256 limit);
    event SetMax(uint256 max);

    function nft() external view returns (address);
    function limit() external view returns (uint256);
    function max() external view returns (uint256);
    function mint(uint256 count) external;
}
