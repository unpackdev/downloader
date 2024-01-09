// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.9;

import "./IERC20.sol";

interface IKeepRegistry {
    function approveOperatorContract(address operatorContract) external;

    function registryKeeper() external view returns (address);
}
