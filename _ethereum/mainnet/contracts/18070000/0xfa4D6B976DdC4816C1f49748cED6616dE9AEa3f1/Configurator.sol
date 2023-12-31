// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./Initializable.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IConfigurator.sol";

contract Configurator is Ownable, AccessControlEnumerable, Initializable {
    
    mapping(bytes32 => address) internal _addressBook;
    mapping(bytes32 => uint) internal _values;
    mapping(bytes32 => bytes) internal _bytes;

    event AddressUpdated(bytes32 id, address indexed oldAddress, address indexed newAddress);
    event ConfigUpdated(bytes32 configId, uint oldValue, uint newValue);
    event BytesConfigUpdated(bytes32 configId, bytes oldValue, bytes newValue);

    constructor() {
    }

    function initialize() external payable initializer {
        address sender = _msgSender();
        _setupRole(DEFAULT_ADMIN_ROLE, sender);
        _setupRole(Roles.ROLE_ADMIN, sender);
        _setupRole(Roles.ROLE_TEMPLATE_CREATOR, sender);
        _setupRole(Roles.ROLE_BOT_CREATOR, sender);
        _transferOwnership(sender);
    }

    function addressOf(bytes32 addrId) external view returns(address) {
        return _addressBook[addrId];
    }

    function configOf(bytes32 configId) external view returns(uint) {
        return _values[configId];
    }

    function bytesConfigOf(bytes32 configId) external view returns(bytes memory) {
        return _bytes[configId];
    }

    function setAddress(bytes32 addrId, address newAddress) external onlyOwner {
        address oldAddress = _addressBook[addrId];
        emit AddressUpdated(addrId, oldAddress, newAddress);
        _addressBook[addrId] = newAddress;
    }

    function setConfig(bytes32 configId, uint newValue) external onlyOwner {
        uint oldValue = _values[configId];
        emit ConfigUpdated(configId, oldValue, newValue);
        _values[configId] = newValue;
    }

    function setBytesConfig(bytes32 configId, bytes calldata newValue) external onlyOwner {
        bytes memory oldValue = _bytes[configId];
        emit BytesConfigUpdated(configId, oldValue, newValue);
        _bytes[configId] = newValue;
    }
}
