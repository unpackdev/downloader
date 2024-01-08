// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITccERC721  {

    function totalSupply() external view returns(uint256);

    function tokenCount() external view returns(uint256);

    function createCollectible(uint256 _number, address to) external;
}
