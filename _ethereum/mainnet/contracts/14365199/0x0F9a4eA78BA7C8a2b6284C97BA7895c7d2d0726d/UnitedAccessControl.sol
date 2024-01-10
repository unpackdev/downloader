// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.9;

import "./IUnitedAuthority.sol";

abstract contract UnitedAccessControl {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IUnitedAuthority indexed authority);

    string private constant UNAUTHORIZED = "UNAUTHORIZED";

    /* ========== STATE VARIABLES ========== */

    IUnitedAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IUnitedAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(IUnitedAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}
