// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./OwnableUpgradeable.sol";
import "./IConfig.sol";

/// Asterizm config contract
abstract contract AsterizmConfig is OwnableUpgradeable, IConfig {

    /// Set initializer event
    /// @param _address address  Initializer address
    event SetInitializerEvent(address _address);

    /// Trusted relay event
    /// @param _initializer address  Update initializer address
    /// @param _relayAddress address  Relay address
    /// @param _fee uint  Relay fee
    /// @param _systemFee uint  System fee
    event TrustedRelayEvent(address indexed _initializer, address indexed _relayAddress, uint _fee, uint _systemFee);

    /// Remove trusted relay event
    /// @param _relayAddress address  Relay address
    event RemoveTrustedRelayEvent(address _relayAddress);

    /// External relay structure
    /// @param exists bool  Is relay exists flag
    /// @param fee uint  Relay fee
    /// @param systemFee uint  System fee
    struct Relay {
        bool exists;
        uint fee;
        uint systemFee;
    }

    mapping(address => Relay) private trustedRelays;

    /// Only trusted relay modifier
    modifier onlyTrustedRelay() {
        require(trustedRelays[msg.sender].exists, "AsterismConfig: only trusted relay");
        _;
    }

    /// Managing trusted relay
    /// @param _relayAddress address  Relay address
    /// @param _fee uint  Relay fee
    /// @param _systemFee uint  System fee
    function manageTrustedRelay(address _relayAddress, uint _fee, uint _systemFee) external onlyOwner {
        trustedRelays[_relayAddress].exists = true;
        trustedRelays[_relayAddress].fee = _fee;
        trustedRelays[_relayAddress].systemFee = _systemFee;

        emit TrustedRelayEvent(msg.sender, _relayAddress, _fee, _systemFee);
    }

    /// Update trusted relay fee
    /// @param _fee uint  Relay fee
    function updateTrustedRelayFee(uint _fee) external override onlyTrustedRelay {
        trustedRelays[msg.sender].fee = _fee;

        emit TrustedRelayEvent(msg.sender, msg.sender, _fee, trustedRelays[msg.sender].systemFee);
    }

    /// Remove trusted relay
    /// @param _relayAddress address  Relay address
    function removeTrustedRelay(address _relayAddress) external onlyOwner {
        require(trustedRelays[_relayAddress].exists, "AsterizmConfig: relay not exists");
        delete trustedRelays[_relayAddress];

        emit RemoveTrustedRelayEvent(_relayAddress);
    }

    /// Return relay data
    /// @param _relayAddress address  External relay address
    /// @return ConfigDataResponseDto
    function getRelayData(address _relayAddress) public view returns(ConfigDataResponseDto memory) {
        ConfigDataResponseDto memory dto;
        dto.externalRelayExists = trustedRelays[_relayAddress].exists;
        dto.externalRelayFee = trustedRelays[_relayAddress].fee;
        dto.systemFee = trustedRelays[_relayAddress].systemFee;

        return dto;
    }
}
