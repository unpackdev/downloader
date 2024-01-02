// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./WmbApp.sol";
// import "./WmbApp.sol";

contract Messager is WmbApp {
    mapping(bytes32 => bytes) public messages;

    constructor(address _wmbGateway) WmbApp() {
        initialize(msg.sender, _wmbGateway);
    }

    function _wmbReceive(
        bytes calldata data,
        bytes32 messageId,
        uint256 /*fromChainId*/,
        address /*fromSC*/
    ) internal override {
		messages[messageId] = data;
    }

    function sendMessage(
        uint256 toChainId, address toAddress, 
        bytes memory msgData, uint256 gasLimit) public payable {
        uint256 fee = estimateFee(toChainId, gasLimit);
        require(msg.value >= fee, "Insufficient fee");
        _dispatchMessage(toChainId, toAddress, msgData, msg.value);
    }
}

