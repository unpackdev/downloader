//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./TONVaultStorage.sol";
import "./VaultProxy.sol";

contract TONVaultProxy is TONVaultStorage, VaultProxy {

    function setBaseInfoProxy(
        string memory _name,
        address _token,
        address _owner,
        address _dividedPool
    ) external onlyProxyOwner {
        name = _name;
        token = _token;
        owner = _owner;
        dividiedPool = _dividedPool;

        if(!isAdmin(_owner)){
            _setupRole(PROJECT_ADMIN_ROLE, _owner);
        }
    }
}
