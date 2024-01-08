// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

interface IOCProtectionSeller{
    function create(address pool, uint256 validTo, uint256 amount, uint256 strike, uint256 deadline, uint256[11] memory data, bytes memory signature) external returns (address);
    function createTo(address pool, uint256 validTo, uint256 amount, uint256 strike, uint256 deadline, uint256[11] memory data, bytes memory signature, address erc721Receiver) external returns (address);
    function version() external view returns (uint32);
}