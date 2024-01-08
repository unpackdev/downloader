// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

interface IVaultBase {
    function addSupportedToken(address tokenAddress) external;

    function setFee(uint256 newFee) external;

    function removeSupportedToken(address tokenAddress) external;

    function depositERC20(uint256 amount, address tokenAddress, bytes calldata data) external payable;

    function depositERC20ForAddress(uint256 amount, address tokenAddress, bytes calldata data, address destination) external payable;
}
