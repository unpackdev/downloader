// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenManagerMin {
    function mint(address _receiver, uint256 _amount) external;

    function burn(address _holder, uint256 _amount) external;
}
