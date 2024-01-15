// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./IManager.sol";
import "./ManagerBase.sol";
import "./PositionManager.sol";
import "./SwapManager.sol";
import "./Multicall.sol";
import "./SelfPermit.sol";

contract Manager is IManager, ManagerBase, SwapManager, PositionManager, Multicall, SelfPermit {
    constructor(address _hub, address _WETH9) ManagerBase(_hub, _WETH9) {}
}
