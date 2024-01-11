// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFayreSharedCollection1155 {
    function mint(address recipient, string memory tokenURI, uint256 amount) external returns(uint256);
}