// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IProtocolConfig} from "IProtocolConfig.sol";
import {Upgradeable} from "Upgradeable.sol";

contract ProtocolConfig is Upgradeable, IProtocolConfig {
    uint256 public protocolFeeRate;
    address public protocolAdmin;
    address public protocolTreasury;
    address public pauserAddress;

    event ProtocolFeeRateChanged(uint256 newProtocolFeeRate);
    event ProtocolAdminChanged(address indexed newProtocolAdmin);
    event ProtocolTreasuryChanged(address indexed newProtocolTreasury);
    event PauserAddressChanged(address indexed newPauserAddress);

    function initialize(
        uint256 _protocolFeeRate,
        address _protocolAdmin,
        address _protocolTreasury,
        address _pauserAddress
    ) external initializer {
        __Upgradeable_init(msg.sender, _pauserAddress);
        protocolFeeRate = _protocolFeeRate;
        protocolAdmin = _protocolAdmin;
        protocolTreasury = _protocolTreasury;
        pauserAddress = _pauserAddress;
    }

    function setProtocolFeeRate(uint256 newFeeRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFeeRate != protocolFeeRate, "ProtocolConfig: New fee needs to be different");
        protocolFeeRate = newFeeRate;
        emit ProtocolFeeRateChanged(newFeeRate);
    }

    function setProtocolAdmin(address newProtocolAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newProtocolAdmin != protocolAdmin, "ProtocolConfig: New protocol admin address needs to be different");
        protocolAdmin = newProtocolAdmin;
        emit ProtocolAdminChanged(newProtocolAdmin);
    }

    function setProtocolTreasury(address newProtocolTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newProtocolTreasury != protocolTreasury, "ProtocolConfig: New protocol treasury address needs to be different");
        protocolTreasury = newProtocolTreasury;
        emit ProtocolTreasuryChanged(newProtocolTreasury);
    }

    function setPauserAddress(address newPauserAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newPauserAddress != pauserAddress, "ProtocolConfig: New pauser address needs to be different");
        pauserAddress = newPauserAddress;
        emit PauserAddressChanged(newPauserAddress);
    }
}
