// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.18;

import "./ERC1967Proxy.sol";
import "./IInverseBondingCurveAdmin.sol";

contract InverseBondingCurveProxy is ERC1967Proxy {
    constructor(address adminContract, address implementation, bytes memory data) ERC1967Proxy(implementation, data) {
        _changeAdmin(adminContract);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return IInverseBondingCurveAdmin(_getAdmin()).curveImplementation();
    }
}
