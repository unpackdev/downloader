// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IComptroller {
    function compSupplySpeeds(address cToken) external view returns (uint256);
}
