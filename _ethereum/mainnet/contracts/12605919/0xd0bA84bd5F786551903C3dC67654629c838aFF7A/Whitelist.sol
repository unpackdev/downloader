// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IWhitelist.sol";
import "./Ownable.sol";

contract Whitelist is IWhitelist, Ownable {

    mapping(address => bool) private _whitelist;
    mapping(address => bool) private _minters;

    modifier onlyMinterOrOwner() {
        require(msg.sender == owner() || _minters[msg.sender] == true, "NotUserAllowed");
        _;
    }

    function addToWhitelist(address account) external override onlyMinterOrOwner {
        _whitelist[account] = true;
    }

    function removeFromWhitelist(address account) external override onlyMinterOrOwner {
        _whitelist[account] = false;
    }

    function isWhitelisted(address account) external view override returns (bool) {
        return _whitelist[account];
    }

    function addMinter(address account) external override onlyMinterOrOwner {
        _minters[account] = true;
    }

    function removeMinter(address account) external override onlyOwner {
        _minters[account] = false;
    }
}
