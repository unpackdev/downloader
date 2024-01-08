// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./BPool.sol";

abstract contract BFactory {
  function newBPool() external virtual returns (BPool);
    function setBLabs(address b) external virtual;
    function collect(BPool pool) external virtual;
    function isBPool(address b) external virtual view returns (bool);
    function getBLabs() external virtual view returns (address);
}