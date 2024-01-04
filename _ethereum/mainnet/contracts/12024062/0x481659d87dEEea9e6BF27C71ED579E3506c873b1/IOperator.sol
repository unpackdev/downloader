// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IEpoch.sol";

interface IOperator {
    function operator() external view returns (address);

    function isOperator() external view returns (bool);

    function transferOperator(address newOperator_) external;
}
