//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "./IProxyCache.sol";
import "./Auth.sol";

contract Proxy is Auth {
    IProxyCache public cache;

    event WriteToCache(address target);

    error ZeroTarget();
    error SetCacheError();
    error Unsuccessful();

    constructor(address _cache) Auth() {
        setCache(_cache);
    }

    function setCache(address _cache) public auth {
        if (_cache == address(0)) {
            revert ZeroTarget();
        }
        cache = IProxyCache(_cache);
    }

    function execute(bytes calldata _code, bytes calldata _data) public payable {
        address target = cache.read(_code);
        if (target == address(0)) {
            target = cache.write(_code);
            emit WriteToCache(target);
        }
        execute(target, _data);
    }

    function execute(address _target, bytes memory _data) public payable auth {
        if (_target == address(0)) {
            revert ZeroTarget();
        }
        (bool success, ) = _target.delegatecall(_data);
        if (!success) {
            revert Unsuccessful();
        }
    }

    function executeCall(
        address _target,
        uint256 _amount,
        bytes memory _data
    ) public payable auth {
        (bool success, ) = _target.call{value: _amount}(_data);
        if (!success) {
            revert Unsuccessful();
        }
    }

    fallback() external payable {}

    receive() external payable {}
}
