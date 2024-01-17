// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IInflation {
    function getToken(address) external;
    function getToken() external;
    function getToken(address[] memory) external;
    function totalMinted() external view returns(uint256);
    function claimable(address) external view returns(uint256);
    function targetMinted() external view returns(uint256);
    function periodicEmission() external view returns(uint256);
    function startInflationTime() external view returns(uint256);
    function periodDuration() external view returns(uint256);
    function sumWeight() external view returns(uint256);
    function weights(address) external view returns(uint256);
    function token() external view returns(address);
    function lastTs() external view returns(uint256);
}
