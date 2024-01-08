// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface ERC20Token {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function balanceOf(address _owner) external returns (uint256 balance);
}
