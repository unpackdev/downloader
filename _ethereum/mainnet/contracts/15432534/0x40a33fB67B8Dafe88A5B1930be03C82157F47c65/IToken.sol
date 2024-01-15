//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IToken {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}
