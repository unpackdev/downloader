// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Context.sol";

abstract contract PausableClaim is Context {
    bool private _claimPaused;

    event ClaimUnpaused(address account);
    event ClaimPaused(address account);

    constructor() {
        _claimPaused = true;
    }

    function claimPaused() public view virtual returns (bool) {
        return _claimPaused;
    }

    modifier whenClaimNotPaused() {
        require(!claimPaused(), "Claim is paused");
        _;
    }

    modifier whenClaimPaused() {
        require(claimPaused(), "Claim is not paused");
        _;
    }

    function _pauseClaim() internal virtual whenClaimNotPaused {
        _claimPaused = true;
        emit ClaimPaused(_msgSender());
    }

    function _unpauseClaim() internal virtual whenClaimPaused {
        _claimPaused = false;
        emit ClaimUnpaused(_msgSender());
    }
}
