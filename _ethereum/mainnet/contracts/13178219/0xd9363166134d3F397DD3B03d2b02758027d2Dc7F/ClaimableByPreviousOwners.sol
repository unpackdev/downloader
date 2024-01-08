pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ContentMixin.sol";

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

abstract contract ClaimableByPreviousOwners is Ownable {
    mapping(address => uint16) _balances;

    constructor() {
        initBalances();
    }

    function initBalances() internal {
        // here will be placed a list of the current owners of another collection on OpenSea
    }

    function howManyFreeTokens() public view returns (uint16) {
        return howManyFreeTokensForAddress(msg.sender);
    }

    function howManyFreeTokensForAddress(address target) public view returns (uint16) {
        uint16 balanceForTarget = _balances[target];

        if (balanceForTarget >= 1) {
            return balanceForTarget;
        }

        return 0;
    }

    function cannotClaimAnymore(address target) internal {
        _balances[target] = 0;
    }

    function setBalanceForOwnerOfPreviousCollection(address target, uint16 amountToSet) public onlyOwner {
        _balances[target] = amountToSet;
    }

}
