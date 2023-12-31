// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC4906.sol";

interface IPerseaSimpleCollectionSeq is IERC4906 {

    function getPrice() external view returns (uint256);

    function payableMint(string memory uriHash) external payable;

    function totalSupply() external view returns (uint256);
}