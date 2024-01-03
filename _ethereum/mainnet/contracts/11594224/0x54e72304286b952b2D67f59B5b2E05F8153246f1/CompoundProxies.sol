pragma solidity ^0.6.0;

import "./AdminAuth.sol";

/// @title Imports Compound position from the account to DSProxy
contract CompoundProxies is AdminAuth {

    mapping(address => address) public proxiesUser;
    mapping(address => bool) public allowed;

    modifier onlyAllowed() {
        require(allowed[msg.sender] || msg.sender == owner);
        _;
    }

    constructor() public {
        allowed[msg.sender] = true;
        allowed[0x5eE6bFa1c2A33c9a655f16eA53B2c7e5B82bC936] = true;
    }

    function addProxyForUser(address _user, address _proxy) public onlyAllowed {
        proxiesUser[_proxy] =_user;
    }

    function addAllowed(address _acc, bool _allowed) public onlyAllowed {
        require(_acc != owner);
        allowed[_acc] = _allowed;
    }
}
