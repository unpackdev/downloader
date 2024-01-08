// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";

/**
 * @dev Contract module which provides a basic whitelist control, where
 * there are account that can be granted exclusive access to
 * specific functions.
 */
contract Whitelist is AccessControlUpgradeable {
    // Create a new role identifier for the minter/burner role
    bytes32 public constant JSTAK_ROLE = keccak256("JSTAK_ROLE");
    mapping(address => bool) whitelist;

    event AddedToWhitelist(address indexed account);
    event AddedToWhitelistInBatch(address[] indexed accounts);
    event RemovedFromWhitelist(address indexed account);
    event RemovedFromWhitelistInBatch(address[] indexed accounts);

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "JSTAK::NOT_WHITELISTED");
        _;
    }

    function addToWhitelist(address _address) external {
        require(
            hasRole(JSTAK_ROLE, msg.sender),
            "JSTAK::CALLER_ISNT_JSTAK_ROLE"
        );
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function addToWhitelistBatch(address[] memory _addresses) external {
        require(
            hasRole(JSTAK_ROLE, msg.sender),
            "JSTAK::CALLER_ISNT_JSTAK_ROLE"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
        emit AddedToWhitelistInBatch(_addresses);
    }

    function removeFromWhitelist(address _address) external {
        require(
            hasRole(JSTAK_ROLE, msg.sender),
            "JSTAK::CALLER_ISNT_JSTAK_ROLE"
        );
        require(
            _address != address(0),
            "JSTAK::CANNOT_REMOVE_ZERO_ADDRESS_FROM_WHITELIST"
        );
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function removeFromWhitelistBatch(address[] memory _addresses) external {
        require(
            hasRole(JSTAK_ROLE, msg.sender),
            "JSTAK::CALLER_ISNT_JSTAK_ROLE"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(
                _addresses[i] != address(0),
                "JSTAK::CANNOT_REMOVE_ZERO_ADDRESS_FROM_WHITELIST"
            );
            whitelist[_addresses[i]] = false;
        }
        emit RemovedFromWhitelistInBatch(_addresses);
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }
}
