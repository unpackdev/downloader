// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";

contract DenyListUpgradeable is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable
{
    bool public isDenylistEnabled;

    mapping(address => bool) public _denylist;

    function setDenylist(bool _enable) public onlyOwner {
        isDenylistEnabled = _enable;
    }

    function addDenylist(address _account, bool _isDenied) public onlyOwner {
        _denylist[_account] = _isDenied;
    }

    function removeDenylist(address _account) public onlyOwner {
        _denylist[_account] = false;
    }
}
