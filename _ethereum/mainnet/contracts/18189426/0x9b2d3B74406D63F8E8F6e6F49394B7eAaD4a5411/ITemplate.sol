// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ITemplate {

    function withdrawToken(address _token, address _target) external returns (uint amount);

}