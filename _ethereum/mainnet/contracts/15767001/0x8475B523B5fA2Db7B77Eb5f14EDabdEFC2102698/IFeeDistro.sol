// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IFeeDistro {
    function claim() external;

    function token() external view returns (address);
}
