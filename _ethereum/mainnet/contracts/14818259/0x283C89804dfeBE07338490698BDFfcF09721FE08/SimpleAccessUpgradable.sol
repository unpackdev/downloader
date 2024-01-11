// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./OwnableUpgradeable.sol";

abstract contract SimpleAccessUpgradable is OwnableUpgradeable {
    
    constructor() {}
    
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(
            authorized[msg.sender] || msg.sender == owner(),
            "Sender is not authorized"
        );
        _;
    }

    function setAuthorized(address _auth, bool _isAuth) external virtual onlyOwner {
        authorized[_auth] = _isAuth;
    }
}
