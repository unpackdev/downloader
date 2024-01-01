//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRNFTV2 {
    function getUserTokens(address _user) external view returns (uint256[] memory);
}