// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IDev {
    function deposit(address _to, uint256 _amount) external returns (bool);

}
