// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.2;

import "./Initializable.sol";

abstract contract FreezeableUpgradeable is Initializable {
    function __Freezeable_init() internal onlyInitializing {
        __Freezeable_init_unchained();
    }

    function __Freezeable_init_unchained() internal onlyInitializing {}

    event Freeze(address account);
    event Thaw(address account);

    mapping(address => bool) private _frozenAccounts;

    function freeze(address account) external virtual isNotFrozen(account) {
        _frozenAccounts[account] = true;
    }

    function thaw(address account) external virtual isFrozen(account) {
        _frozenAccounts[account] = false;
    }

    function frozen(address account) public view returns (bool) {
        return _frozenAccounts[account];
    }

    modifier isFrozen(address account) {
        require(frozen(account), "Freezeable: address is not frozen");
        _;
    }

    modifier isNotFrozen(address account) {
        require(!frozen(account), "Freezeable: address is frozen");
        _;
    }
}
