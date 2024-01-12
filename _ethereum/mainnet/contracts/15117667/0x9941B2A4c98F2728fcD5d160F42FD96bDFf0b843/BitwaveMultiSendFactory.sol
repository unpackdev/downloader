// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./BitwaveMultiSend.sol";


/// @title A factory contract for Multi-Send contracts.
/// @author Bitwave
/// @author Inish Crisson
/// @notice Now with support for fallback functions.
contract BitwaveMultiSendFactory {

    mapping(address => address) public multiSendAddressMap;
    event newMultiSend(address owner, address multiPayChild);
    uint8 public bwChainId;

    constructor(uint8 _bwChainId) {
        bwChainId = _bwChainId;
    }

/// @notice Deploys a new Bitwave Multi-Send Contract
/// @return newBitwaveMultiSend The address of the deployed contract.
    function deployNewMultiSend() public returns (address) {
        require (multiSendAddressMap[msg.sender] == address(0x0));
        BitwaveMultiSend newBitwaveMultiSend = new BitwaveMultiSend(msg.sender, bwChainId);
        multiSendAddressMap[msg.sender] = address(newBitwaveMultiSend);
        emit newMultiSend(msg.sender, address(newBitwaveMultiSend));
        return (address(newBitwaveMultiSend));
    }
}