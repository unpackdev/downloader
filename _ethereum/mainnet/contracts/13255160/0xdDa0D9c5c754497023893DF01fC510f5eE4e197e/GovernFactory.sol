/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;

import "./IERC3000.sol";
import "./Govern.sol";
import "./ERC1167ProxyFactory.sol";
import "./AddressUtils.sol";

contract GovernFactory {
    using ERC1167ProxyFactory for address;
    using AddressUtils for address;
    
    address public base;

    constructor() public {
        setupBase();
    }

    function newGovern(IERC3000 _initialExecutor, bytes32 _salt) public returns (Govern govern) {
        if (_salt != bytes32(0)) {
            return Govern(base.clone2(_salt, abi.encodeWithSelector(govern.initialize.selector, _initialExecutor)).toPayable());
        } else {
            return new Govern(address(_initialExecutor));
        }
    }

    function setupBase() private {
        base = address(new Govern(address(2)));
    }
}
