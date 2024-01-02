// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";

interface ILatchWeb3 {
    function getStatus(address accountClient) external view returns (bool);
}

abstract contract Web3Latchable is Ownable {
    address private _latchProxy;

    event LatchProxyUpdated(address newLatchProxy);

    function latchProxy() public view returns (address) {
        return _latchProxy;
    }

    function _setLatchProxy(address _newProxy) internal {
        _latchProxy = _newProxy;
        emit LatchProxyUpdated(_newProxy);
    }

    function isLatchOpen() internal view returns (bool) {
        if (_latchProxy != address(0)) {
            return !ILatchWeb3(_latchProxy).getStatus(_msgSender());
        }
        return true;
    }
}
