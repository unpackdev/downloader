// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IGToken {
    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}
