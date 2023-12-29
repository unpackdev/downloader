// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICustomizedCondition {
    function getStatus(address _tokenAddress, address _sender) external view returns(bool);
}
