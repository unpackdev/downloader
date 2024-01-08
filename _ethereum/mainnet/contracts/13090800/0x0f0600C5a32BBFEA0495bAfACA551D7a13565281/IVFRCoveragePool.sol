// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IVesperPool.sol";

interface IVFRCoveragePool is IVesperPool {
    function buffer() external view returns (address);
}
