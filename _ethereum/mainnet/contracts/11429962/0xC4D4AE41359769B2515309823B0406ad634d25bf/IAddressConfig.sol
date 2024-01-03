// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IAddressConfig {
    function lockup() external view returns (address);
}
