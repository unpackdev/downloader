// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Context.sol";

abstract contract Adminable is Context {
    address private _admin;

    event AdminshipTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    constructor() {
        address msgSender = _msgSender();
        _admin = msgSender;
        emit AdminshipTransferred(address(0), msgSender);
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    modifier onlyAdmin() {
        require(admin() == _msgSender(), "Adminable: caller is not the admin");
        _;
    }

    function _transferAdminship(address newAdmin) internal {
        require(
            newAdmin != address(0),
            "Adminable: new admin is the zero address"
        );
        emit AdminshipTransferred(_admin, newAdmin);
        _admin = newAdmin;
    }
}
