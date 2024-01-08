// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AccessControlEnumerable.sol";

contract ManifestAdmin is AccessControlEnumerable {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Manifest: must have admin role"
        );
        _;
    }
}
