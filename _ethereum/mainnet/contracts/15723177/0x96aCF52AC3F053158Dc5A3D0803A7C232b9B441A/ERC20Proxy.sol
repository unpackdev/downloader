// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./TransparentUpgradeableProxy.sol";

/**
 * @title Proxy
 * @dev This contract implements a proxy that is upgradeable by an admin.
 */
contract ERC20Proxy is TransparentUpgradeableProxy {
    /**
     * @dev Constructor which inits at contract creation.
     */
    constructor(
        address _logic,
        address admin_,
        string memory name,
        string memory symbol,
        uint256 initialBalance
    ) TransparentUpgradeableProxy(
        _logic,
        admin_ ,
        abi.encodeWithSelector(
            bytes4(0xb119490e) // bytes4(keccak256("initialize(string,string,uint256)"))
            ,name,symbol,initialBalance
        )
    ) {}
}