// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IProtocolConfig} from "IProtocolConfig.sol";
import {Upgradeable} from "Upgradeable.sol";

contract ProtocolConfig is Upgradeable, IProtocolConfig {
    uint256 public protocolFee;
    address public protocolAddress;
    uint256 public automatedLineOfCreditPremiumFee;
    address public pauserAddress;

    event ProtocolFeeChanged(uint256 newProtocolFee);
    event ProtocolAddressChanged(address indexed newProtocolAddress);
    event PauserAddressChanged(address indexed newPauserAddress);
    event AutomatedLineOfCreditPremiumFeeChanged(uint256 newFee);

    function initialize(
        uint256 _protocolFee,
        address _protocolAddress,
        uint256 _automatedLineOfCreditPremiumFee,
        address _pauserAddress
    ) external initializer {
        __Upgradeable_init(msg.sender, _pauserAddress);
        protocolFee = _protocolFee;
        protocolAddress = _protocolAddress;
        automatedLineOfCreditPremiumFee = _automatedLineOfCreditPremiumFee;
        pauserAddress = _pauserAddress;
    }

    function setProtocolFee(uint256 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFee != protocolFee, "ProtocolConfig: New fee needs to be different");
        protocolFee = newFee;
        emit ProtocolFeeChanged(newFee);
    }

    function setProtocolAddress(address newProtocolAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newProtocolAddress != protocolAddress, "ProtocolConfig: New protocol address needs to be different");
        protocolAddress = newProtocolAddress;
        emit ProtocolAddressChanged(newProtocolAddress);
    }

    function setPauserAddress(address newPauserAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newPauserAddress != pauserAddress, "ProtocolConfig: New pauser address needs to be different");
        pauserAddress = newPauserAddress;
        emit PauserAddressChanged(newPauserAddress);
    }

    function setAutomatedLineOfCreditPremiumFee(uint256 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFee != automatedLineOfCreditPremiumFee, "ProtocolConfig: New fee needs to be different");
        automatedLineOfCreditPremiumFee = newFee;
        emit AutomatedLineOfCreditPremiumFeeChanged(newFee);
    }
}
