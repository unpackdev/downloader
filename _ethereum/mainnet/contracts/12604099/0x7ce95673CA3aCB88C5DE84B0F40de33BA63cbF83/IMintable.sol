// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

interface IMintable {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}
