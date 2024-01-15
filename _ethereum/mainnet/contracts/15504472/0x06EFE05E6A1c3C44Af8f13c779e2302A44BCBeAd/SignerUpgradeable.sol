// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./AdminManagerUpgradable.sol";

contract SignerUpgradeable is Initializable, EIP712Upgradeable, AdminManagerUpgradable {
    using ECDSAUpgradeable for bytes32;

    address public signer;

    function __Signer_init(string memory name, string memory version, address signer_) internal onlyInitializing {
        __AdminManager_init_unchained();
        __Signer_init_unchained(name, version, signer_);
        __EIP712_init(name, version);
    }

    function __Signer_init_unchained(string memory name, string memory version, address signer_)
        internal
        onlyInitializing
    {
        __EIP712_init(name, version);
        signer = signer_;
    }

    function _verify(bytes32 digest, bytes calldata signature)
        internal
        view
        returns (bool)
    {
        address recoveredSigner = digest.recover(signature);
        return signer == recoveredSigner;
    }

    uint256[49] private __gap;
}