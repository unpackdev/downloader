// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

abstract contract Proxy {
    address private _proxy;

    constructor(address proxy_) {
        _proxy = proxy_;
    }

    modifier onlyFromProxy() {
        _checkProxy();
        _;
    }

    function proxy() public view virtual returns (address) {
        return _proxy;
    }

    function _checkProxy() internal view virtual {
        require(proxy() == msg.sender, "Caller is not proxy");
    }
}