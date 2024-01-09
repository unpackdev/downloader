// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Context.sol";


contract Owned is Context {
    address private _contractOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() { 
        _contractOwner = payable(_msgSender()); 
    }

    function owner() public view virtual returns(address) {
        return _contractOwner;
    }

    function _transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Owned: Address can not be 0x0");
        __transferOwnership(newOwner);
    }


    function _renounceOwnership() external virtual onlyOwner {
        __transferOwnership(address(0));
    }

    function __transferOwnership(address _to) internal {
        emit OwnershipTransferred(owner(), _to);
        _contractOwner = _to;
    }


    modifier onlyOwner() {
        require(_msgSender() == _contractOwner, "Owned: Only owner can operate");
        _;
    }
}



contract Accessable is Owned {
    mapping(address => bool) private _admins;
    mapping(address => bool) private _tokenClaimers;

    constructor() {
        _admins[_msgSender()] = true;
        _tokenClaimers[_msgSender()] = true;
    }

    function isAdmin(address user) public view returns(bool) {
        return _admins[user];
    }

    function isTokenClaimer(address user) public view returns(bool) {
        return _tokenClaimers[user];
    }


    function _setAdmin(address _user, bool _isAdmin) external onlyOwner {
        _admins[_user] = _isAdmin;
        require( _admins[owner()], "Accessable: Contract owner must be an admin" );
    }

    function _setTokenClaimer(address _user, bool _isTokenCalimer) external onlyOwner {
        _tokenClaimers[_user] = _isTokenCalimer;
        require( _tokenClaimers[owner()], "Accessable: Contract owner must be an token claimer" );
    }


    modifier onlyAdmin() {
        require(_admins[_msgSender()], "Accessable: Only admin can operate");
        _;
    }

    modifier onlyTokenClaimer() {
        require(_tokenClaimers[_msgSender()], "Accessable: Only Token Claimer can operate");
        _;
    }
}