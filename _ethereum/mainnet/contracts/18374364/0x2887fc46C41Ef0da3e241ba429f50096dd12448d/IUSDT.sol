// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IUSDT {
    function approve(address _spender, uint256 _value) external;
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external;
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}