// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IProtocolConfig} from "IProtocolConfig.sol";
import {InitializableManageable} from "InitializableManageable.sol";

contract ProtocolConfig is InitializableManageable, IProtocolConfig {
    uint256 public override protocolFee;
    address public override protocolAddress;

    event ProtocolFeeChanged(uint256 newProtocolFee);
    event ProtocolAddressChanged(address newProtocolAddress);

    constructor() InitializableManageable(msg.sender) {}

    function initialize(uint256 _protocolFee, address _protocolAddress) external initializer {
        InitializableManageable.initialize(msg.sender);
        protocolFee = _protocolFee;
        protocolAddress = _protocolAddress;
    }

    function setProtocolFee(uint256 newFee) public onlyManager {
        protocolFee = newFee;
        emit ProtocolFeeChanged(newFee);
    }

    function setProtocolAddress(address newProtocolAddress) public onlyManager {
        protocolAddress = newProtocolAddress;
        emit ProtocolAddressChanged(newProtocolAddress);
    }
}
