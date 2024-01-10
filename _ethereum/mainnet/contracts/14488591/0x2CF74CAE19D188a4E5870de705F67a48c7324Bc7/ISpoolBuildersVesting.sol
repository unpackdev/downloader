// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./IBaseVesting.sol";

/**
 * @notice {ISpoolBuildersVesting} interface.
 *
 * @dev See {SpoolBuildersVesting} for function descriptions.
 *
 */
interface ISpoolBuildersVesting is IBaseVesting {
    function setVests(address[] calldata members, uint192[] calldata amounts)
        external;
}
