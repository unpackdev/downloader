// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

interface IOCProtectionStorage{
    function getProtectionData(uint256 id) external view returns (address, uint256, uint256, uint256, uint, uint);
    function withdrawPremium(uint256 _id, uint256 _premium) external;
}

interface IOCProtections{
    function getProtectionData(uint256 id) external view returns (address, uint256, uint256, uint256, uint, uint);
    function withdrawPremium(uint256 _id, uint256 _premium) external;
    function create(address pool, uint256 validTo, uint256 amount, uint256 strike, uint256 deadline, uint256[11] memory data, bytes memory signature) external returns (address);
    function createTo(address pool, uint256 validTo, uint256 amount, uint256 strike, uint256 deadline, uint256[11] memory data, bytes memory signature, address erc721Receiver) external returns (address);
    function exercise(uint256 _id, uint256 _amount) external;
    function version() external view returns (uint32);
}