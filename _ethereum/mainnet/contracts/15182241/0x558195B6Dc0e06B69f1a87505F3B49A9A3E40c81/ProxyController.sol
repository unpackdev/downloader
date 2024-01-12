// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ProxyModel.sol";
import "./AddressUtils.sol";
import "./IntegerUtils.sol";

abstract contract ProxyController is ProxyModel {
    using AddressUtils for address;
    using IntegerUtils for uint256;

    function Proxy_(address init, bytes memory data) internal virtual {
        data.length.enforceIsNotZero();
        init.enforceIsContract();
        _Proxy(init, data);
    }

    function fallback_() internal virtual {
        _delegate(implementation_());
    }

    function implementation_() internal view virtual returns (address);
}
