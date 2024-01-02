// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Initializable.sol";
import "./IIntentBridge.sol";

contract Account is Initializable {
    address public constant INTENT_BRIDGE = 0x1A9F622DFafAD5373741D821F1431Abb23C30529;

    address public owner;

    uint16 public dstChainId;
    address public dstToken;

    address public receiver;

    function initialize(address _owner, address _receiver, uint16 _dstChainId, address _dstToken) external initializer {
        owner = _owner;
        receiver = _receiver;
        dstChainId = _dstChainId;
        dstToken = _dstToken;
    }

    receive() external payable {
        IIntentBridge(INTENT_BRIDGE).bridgeETH{value: msg.value}(dstChainId, dstToken, msg.sender, receiver, msg.value);
    }
}
