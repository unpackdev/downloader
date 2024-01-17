// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface ITokenBurn {
    function burn(address _from, uint256 _amount) external returns (bool);
}
