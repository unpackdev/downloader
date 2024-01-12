// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.15;

import "./UUPSUpgradeable.sol";

/* solhint-disable reason-string */
contract InitContract is UUPSUpgradeable {
    function prepare(address newAdmin) public {
        address _admin = _getAdmin();
        require(_getImplementation() != address(0));
        require(_admin == address(0) || _admin == newAdmin);
        _changeAdmin(newAdmin);
    }

    function _authorizeUpgrade(address) internal view override {
        require(_getAdmin() == msg.sender);
    }
}
