// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Initializable.sol";
import "./InitializableStorage.sol";
import "./LibDiamond.sol";

abstract contract EIP2535Initializable is Initializable {

    // override Initializable::initializer modifier
    modifier EIP2535Initializer() {
        require(!InitializableStorage.layout()._initializing && InitializableStorage.layout()._initialized < 1, "Initializable: contract is already initialized");
        InitializableStorage.layout()._initialized = 1;
        InitializableStorage.layout()._initializing = true;
        _;
        // multiple facet contracts needed initialization on deployment
        InitializableStorage.layout()._initialized = 0;
        InitializableStorage.layout()._initializing = false;
    }

    modifier EIP2535Reinitializer(uint8 version) {
        require(!InitializableStorage.layout()._initializing && InitializableStorage.layout()._initialized < version, "Initializable: contract is already initialized");
        InitializableStorage.layout()._initialized = version;
        InitializableStorage.layout()._initializing = true;
        _;
        // multiple facet contracts needed re-initialization on ugrades for instance
        InitializableStorage.layout()._initialized = 0;
        InitializableStorage.layout()._initializing = false;
        }

}
