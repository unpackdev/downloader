// SPDX-License-Identifier: MIT
pragma solidity >=0.6.5 <0.8.0;

interface IDetailedERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}
