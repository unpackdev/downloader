//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IGasStationTokensStore {
    function feeTokens() external view returns (address[] memory);
    function addFeeToken(address _token) external;
    function removeFeeToken(address _token) external;
    function isAllowedToken(address _token) external view returns (bool);
}
