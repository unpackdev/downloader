// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IWrappedLooksRareToken {
    function LOOKS() external view returns (address);

    function wrap(uint256 amount) external;
}
