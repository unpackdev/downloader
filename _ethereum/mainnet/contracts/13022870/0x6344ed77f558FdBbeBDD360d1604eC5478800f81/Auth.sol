//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "./IAuthority.sol";

contract Auth {
    IAuthority public authority;
    address public owner;

    error Unauthorized();

    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);

    constructor() {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(address authority_) public auth {
        authority = IAuthority(authority_);
        emit LogSetAuthority(authority_);
    }

    modifier auth() {
        if (!isAuthorized(msg.sender, msg.sig)) {
            revert Unauthorized();
        }
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (address(authority) == address(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}
