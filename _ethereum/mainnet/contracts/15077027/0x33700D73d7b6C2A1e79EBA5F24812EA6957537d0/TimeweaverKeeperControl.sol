// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
// modified from @dievardump's https://github.com/dievardump/polygon-dex/blob/main/contracts/Access/OwnerOperatorControl.sol

import "./AccessControlUpgradeable.sol";

abstract contract TimeweaverKeeperControl is AccessControlUpgradeable {
    bytes32 public constant TIMEWEAVER_ROLE = keccak256("TIMEWEAVER_ROLE");

    function __TimeweaverKeeperControl_init() internal {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyTimekeeper() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Role: not Timekeeper");
        _;
    }

    modifier onlyTimeweaver() {
        require(isTimeweaver(_msgSender()), "Role: not Timeweaver");
        _;
    }

    function isTimeweaver(address _address) public view returns (bool) {
        return hasRole(TIMEWEAVER_ROLE, _address);
    }

    function addTimeweavers(address[] calldata timeweavers) external onlyTimekeeper {
        for (uint256 i; i < timeweavers.length; i++) {
            require(
                timeweavers[i] != address(0),
                "Address cannot be null address."
            );
            grantRole(TIMEWEAVER_ROLE, timeweavers[i]);
        }
    }

    function removeTimeweavers(address[] calldata timeweavers) external onlyTimekeeper {
        for (uint256 i; i < timeweavers.length; ++i) {
            revokeRole(TIMEWEAVER_ROLE, timeweavers[i]);
        }
    }
}
