// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenericBurnableFrom {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}
