// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Whitelist {
    event Listed(address account);
    event Unlisted(address account);

    bool private _useWhitelist = false;
    uint private _whitelistMintLimit = 3;

    mapping(address => bool) internal whitelistApprovals;

    modifier whenUseWhitelist() {
        if (_useWhitelist) {
            require(whitelistApprovals[msg.sender], "Caller not in whitelist");
        }
        _;
    }

    function _setWhitelistLimit(uint _limit) internal virtual {
        _whitelistMintLimit = _limit;
    }

    function _enableWhitelist() internal virtual {
        _useWhitelist = true;
    }

    function _disableWhitelist() internal virtual {
        _useWhitelist = false;
    }

    function _addWhitelist(address account) internal virtual {
        whitelistApprovals[account] = true;
        emit Listed(account);
    }

    function _removeWhitelist(address account) internal virtual {
        delete whitelistApprovals[account];
        emit Unlisted(account);
    }

    function hasWhitelist(address account) public view virtual returns (bool) {
        return whitelistApprovals[account];
    }

    function useWhitelist() public view virtual returns (bool) {
        return _useWhitelist;
    }

    function whitelistMintLimit() public view virtual returns (uint) {
        return _whitelistMintLimit;
    }
}
