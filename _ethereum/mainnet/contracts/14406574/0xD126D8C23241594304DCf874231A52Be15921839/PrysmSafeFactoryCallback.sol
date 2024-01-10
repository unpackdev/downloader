// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IProxyCreationCallback.sol";
import "./GnosisSafeProxy.sol";

/// @custom:security-contact security@prysm.xyz
contract PrysmSafeFactoryCallback is Ownable, IProxyCreationCallback {
    event PrysmSquadCreate(GnosisSafeProxy proxy, address singleton);

    function proxyCreated(GnosisSafeProxy proxy, address _singleton, bytes calldata /*initializer*/, uint256 /*saltNonce*/) external override {
        emit PrysmSquadCreate(proxy, _singleton);
    }
}

