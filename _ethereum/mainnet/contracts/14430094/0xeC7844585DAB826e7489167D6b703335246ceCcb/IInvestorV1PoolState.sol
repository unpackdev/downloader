// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolState {
    function funded() external view returns (uint256);
    function exited() external view returns (uint256);
    function restaked() external view returns (uint256);
    function oraclePrice() external view returns (uint256);
    function getPoolState() external view returns (string memory);
    function pooledAmt(address user) external view returns (uint256);
    function restakeAmt(address user) external view returns (uint256);
    function claimed(address user) external view returns (bool);
    function collateralDocument() external view returns (string memory);
    function detailLink() external view returns (string memory);
    function collateralHash() external view returns (string memory);
    function depositors() external view returns (uint256);
    function restakers() external view returns (uint256);
    function depositorList(uint256 index) external view returns (address);
    function restakerList(uint256 index) external view returns (address);
    function getInfo(address _account) external view returns (string memory, string memory, uint256, uint256, uint256, uint256, uint256, uint24);
    function getExtra() external view returns (address, uint256, uint256, uint256, string memory, string memory, string memory);
}