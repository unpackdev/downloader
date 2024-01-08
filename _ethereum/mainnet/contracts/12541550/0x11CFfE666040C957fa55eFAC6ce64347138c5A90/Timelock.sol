// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ITimelockTarget.sol";

import "./SafeMath.sol";
import "./IERC20.sol";

contract Timelock {
    using SafeMath for uint256;

    uint256 public buffer;
    address public admin;

    mapping (bytes32 => uint256) public pendingActions;

    event SignalPendingAction(bytes32 action);
    event SignalSetGov(address target, address gov, bytes32 action);
    event ClearAction(bytes32 action);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Timelock: forbidden");
        _;
    }

    constructor(uint256 _buffer) public {
        buffer = _buffer;
        admin = msg.sender;
    }

    function signalSetGov(address _target, address _gov) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setGov", _target, _gov));
        _setPendingAction(action);
        emit SignalSetGov(_target, _gov, action);
    }

    function setGov(address _target, address _gov) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setGov", _target, _gov));
        _validateAction(action);
        ITimelockTarget(_target).setGov(_gov);
        _clearAction(action);
    }

    function cancelAction(bytes32 _action) external onlyAdmin {
        _clearAction(_action);
    }

    function _setPendingAction(bytes32 _action) private {
        pendingActions[_action] = block.timestamp.add(buffer);
        emit SignalPendingAction(_action);
    }

    function _validateAction(bytes32 _action) private view {
        require(pendingActions[_action] != 0, "Timelock: action not signalled");
        require(pendingActions[_action] < block.timestamp, "Timelock: action time not yet passed");
    }

    function _clearAction(bytes32 _action) private {
        require(pendingActions[_action] != 0, "Timelock: invalid _action");
        delete pendingActions[_action];
        emit ClearAction(_action);
    }
}
