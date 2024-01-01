// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ITorn {
    function rescueTokens(address _token, address payable _to, uint256 _balance) external;
}
