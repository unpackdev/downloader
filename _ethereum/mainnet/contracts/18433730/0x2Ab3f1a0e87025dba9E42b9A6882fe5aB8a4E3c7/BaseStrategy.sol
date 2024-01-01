// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IStrategy.sol";

abstract contract BaseStrategy is IStrategy {
    struct Storage {
        bytes immutableParams;
        bytes mutableParams;
        uint256 previousState;
        uint256 currentState;
    }

    bytes32 public constant STORAGE_POSITION = keccak256("strategy.storage");

    function _contractStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
    }

    modifier onlyOwner() virtual {
        _;
    }

    modifier onlyVault() virtual {
        _;
    }

    modifier ensureNoMEV() virtual {
        _;
    }

    function getNextState(uint256 currentState) public view virtual returns (uint256 nextState);

    function getCurrentState() public pure returns (uint256) {
        Storage memory s = _contractStorage();
        return s.currentState;
    }

    function getPreviousState() public pure returns (uint256) {
        Storage memory s = _contractStorage();
        return s.previousState;
    }

    function checkStateAfterRebalance() external view ensureNoMEV returns (bool) {
        uint256 currentState = getCurrentState();
        uint256 previousState = getPreviousState();
        uint256 expectedState = getNextState(previousState);
        return expectedState == currentState;
    }

    function canStartAuction() external view ensureNoMEV returns (bool) {
        uint256 currentState = getCurrentState();
        uint256 expectedState = getNextState(currentState);
        return expectedState != currentState;
    }

    function canStopAuction() external view ensureNoMEV returns (bool) {
        uint256 currentState = getCurrentState();
        uint256 expectedState = getNextState(currentState);
        return expectedState == currentState;
    }

    function updateMutableParams(bytes memory mutableParams) external onlyOwner {
        Storage storage s = _contractStorage();
        s.mutableParams = abi.encode(mutableParams);
    }

    function analyzeCurrentState() public view virtual returns (uint256);

    function saveState() external virtual;
}
