// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// Import contract UUPS
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";

contract Box is Initializable, UUPSUpgradeable, AccessControlUpgradeable {
    uint256 private _value;

    function initialize(uint256 value) public initializer {
        _value = value;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function getValue() public view returns (uint256) {
        return _value;
    }

    function _authorizeUpgrade(
        address
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
