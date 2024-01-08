// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IConverter {
    function convert(uint256 amount) external;

    function source() external view returns (address);

    function destination() external view returns (address);
}
