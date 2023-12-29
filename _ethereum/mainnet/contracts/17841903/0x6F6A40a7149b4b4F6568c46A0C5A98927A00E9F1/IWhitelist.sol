// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWhitelist {
    function getStatus(address _tokenAddress, address _participant) external view returns(bool);
}