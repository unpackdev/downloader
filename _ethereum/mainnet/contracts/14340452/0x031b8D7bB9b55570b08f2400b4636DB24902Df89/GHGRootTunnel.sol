// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FxBaseRootTunnel.sol";
import "./Ownable.sol";

contract GHGRootTunnel is FxBaseRootTunnel, Ownable {

    mapping(address => bool) public authorizedUsers;

    event CallMade(address target, bool success, bytes data);

    constructor(address _checkpointManager, address _fxRoot) FxBaseRootTunnel(_checkpointManager, _fxRoot) {}

    //////////////   ADMIN FUNCTIONS   //////////////

    function setFxChildTunnel(address _fxChildTunnel) external onlyOwner {
        _setFxChildTunnel(_fxChildTunnel);
    }

    function setAuthorizedUser(address _addr, bool _status) external onlyOwner {
        authorizedUsers[_addr] = _status;
    }

    function replayCall(address _target, bytes memory _data, bool _reqSuccess) external onlyOwner {
        (bool succ, ) = _target.call(_data);
        if (_reqSuccess) require(succ, "Call Failed");
    }

    //////////////   PORTAL FUNCTIONS   //////////////

    function sendMessage(bytes calldata _message) external {
        require(authorizedUsers[msg.sender], "Message Sender is not Authorized to Use Tunnel");
        _sendMessageToChild(_message);
    }

    function _processMessageFromChild(bytes memory _message) internal override {
        (address target, bytes[] memory calls ) = abi.decode(_message, (address, bytes[]));
        for (uint i = 0; i < calls.length; i++) {
            (bool succ, ) = target.call(calls[i]);
            emit CallMade(target, succ, calls[i]);
        }
    }
}
