// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

interface ILL420OGToken {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}
