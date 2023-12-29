// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./ERC1967Proxy.sol";

contract UpgradeabilityProxy is ERC1967Proxy {
    constructor(address _logic, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(msg.sender);
    }

    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    function changeAdmin(address newAdmin) external ifAdmin {
        _changeAdmin(newAdmin);
    }

    function admin() external view returns (address) {
        return _getAdmin();
    }

    function implementation() external view returns (address) {
        return ERC1967Proxy._implementation();
    }
}
