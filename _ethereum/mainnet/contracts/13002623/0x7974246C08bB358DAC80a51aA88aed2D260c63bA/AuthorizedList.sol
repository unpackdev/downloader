// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./Address.sol";
import "./Ownable.sol";

abstract contract AuthorizedList is Context, Ownable
{
    using Address for address;

    mapping(address => bool) internal authorizedCaller;

    modifier authorized() {
        require(authorizedCaller[_msgSender()] || _msgSender() == _owner, "You are not authorized to use this function");
        require(_msgSender() != address(0), "Zero address is not a valid caller");
        _;
    }

    constructor() Ownable() {
        authorizedCaller[_msgSender()] = true;
    }

    function authorizeCaller(address authAddress, bool shouldAuthorize) external authorized {
        authorizedCaller[authAddress] = shouldAuthorize;
    }
}
