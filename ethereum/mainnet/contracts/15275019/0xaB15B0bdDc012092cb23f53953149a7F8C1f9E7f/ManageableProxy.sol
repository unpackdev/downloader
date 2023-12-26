// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "./TransparentUpgradeableProxy.sol";
import "./ERC1967Proxy.sol";

import "./IGovernable.sol";

abstract contract ManageableProxy is ERC1967Proxy {

    constructor(IGovernable governable, address defaultVersion, bytes memory inputData) ERC1967Proxy(defaultVersion, inputData) {
        _changeAdmin(address(governable));
    }

    function getCurrentVersion() public view returns (address) {
        return _implementation();
    }

    modifier onlyFromGovernance() {
        require(msg.sender == IGovernable(_getAdmin()).getGovernanceAddress(), "ManageableProxy: only governance");
        _;
    }

    function upgradeToAndCall(address impl, bytes memory data) external onlyFromGovernance {
        _upgradeToAndCall(impl, data, false);
    }
}
