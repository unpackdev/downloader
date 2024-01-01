// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMintable.sol";
import "./BaseBridge.sol";

contract SidechainBridge is BaseBridge {
    function initialize(address _token) public initializer {
        __Bridge_init(_token);
    }

    function _sendToken(uint _amount) internal override {
        IMintable(innerToken).burn(msg.sender, _amount);
    }

    function _recvToken(address _receiver, uint _amount) internal override {
        IMintable(innerToken).mint(_receiver, _amount);
    }
}
