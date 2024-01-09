// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0;

interface IvPHTR {
    function PHTR() external view returns (address);

    function ePHTR() external view returns (address);

    function balanceOf(address account) external view returns (uint);
}
