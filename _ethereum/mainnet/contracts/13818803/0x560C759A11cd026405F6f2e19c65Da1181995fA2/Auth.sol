// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

abstract contract Auth {

    event SetOwner(address indexed owner);
    event SetTrusted(address indexed user, bool isTrusted);

    address public owner;

    mapping(address => bool) public isTrusted;

    error OnlyOwner();
    error OnlyTrusted();

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier onlyTrusted() {
        if (!isTrusted[msg.sender]) revert OnlyTrusted();
        _;
    }

    constructor(address _owner, address _trusted) {
        owner = _owner;
        isTrusted[_trusted] = true;

        emit SetOwner(owner);
        emit SetTrusted(_trusted, true);
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit SetOwner(owner);
    }

    function setTrusted(address _user, bool _isTrusted) external onlyOwner {
        isTrusted[_user] = _isTrusted;
        emit SetTrusted(_user, _isTrusted);
    }

}
