// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
interface IAiFiStaking {
    function depositAiFi(address _depositor, uint256 _amount) external;
}