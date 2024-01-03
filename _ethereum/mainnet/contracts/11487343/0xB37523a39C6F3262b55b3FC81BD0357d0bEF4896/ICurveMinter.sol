// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @notice Interface for Curve.fi's CRV minter.
 */
interface ICurveMinter {
    function mint(address) external;
}