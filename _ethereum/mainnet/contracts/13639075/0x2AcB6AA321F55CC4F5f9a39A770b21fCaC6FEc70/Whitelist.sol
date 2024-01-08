// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./ERC165.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";

abstract contract Whitelist is Ownable {

    event AddToWhitelist(address indexed account, address indexed sender);
    event RemoveFromWhitelist(address indexed account, address indexed sender);

    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _whitelist;

    modifier onlyWhitelisted() {
        require(owner() == msg.sender || _whitelist.contains(msg.sender), "You're not whitelisted to perform this action.");
        _;
    }   

    function getWhitelisted() external view returns (address[] memory) {
        address[] memory whitelisted = new address[](_whitelist.length());
        for (uint i = 0; i < _whitelist.length(); i++) {
            whitelisted[i] = _whitelist.at(i);
        }
        return whitelisted;
    }

    function addWhitelist(address user) external onlyOwner {
        if (!_whitelist.contains(user)) {
            emit AddToWhitelist(user, msg.sender);
            _whitelist.add(user);
        }
    }

    function removeWhitelist(address user) external onlyOwner {
        if (_whitelist.contains(user)) {
            emit RemoveFromWhitelist(user, msg.sender);
            _whitelist.remove(user);
        }
    }

    function isWhitelisted(address user) public view returns (bool) {
        return (owner() == user || _whitelist.contains(user));
    }

}