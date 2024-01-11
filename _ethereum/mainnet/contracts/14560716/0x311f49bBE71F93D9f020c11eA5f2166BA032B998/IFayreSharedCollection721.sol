// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFayreSharedCollection721 {
    function mint(address recipient, string memory tokenURI) external returns(uint256);
}