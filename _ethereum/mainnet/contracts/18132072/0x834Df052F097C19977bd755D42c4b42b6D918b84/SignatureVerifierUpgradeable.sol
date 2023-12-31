// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Initializable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./ISignatureVerifierUpgradeable.sol";
import "./Types.sol";
import "./Constants.sol";

contract SignatureVerifierUpgradeable is
    ISignatureVerifierUpgradeable,
    Initializable,
    AccessControlEnumerableUpgradeable,
    EIP712Upgradeable
{
    uint8 internal _threshHold;

    function __SignatureVerifier_init(
        string calldata name_,
        string calldata version_,
        uint8 threshold_
    ) internal onlyInitializing {
        __SignatureVerifier_init_unchained(name_, version_, threshold_);
    }

    function __SignatureVerifier_init_unchained(
        string calldata name_,
        string calldata version_,
        uint8 threshold_
    ) internal onlyInitializing {
        __AccessControlEnumerable_init_unchained();
        __EIP712_init_unchained(name_, version_);
        _setThreshhold(threshold_);
    }

    function _setThreshhold(uint8 threshold_) internal {
        if (threshold_ == 0) revert LowThreshold();
        _threshHold = threshold_;
    }

    /* ========== VIEW ========== */

    function threshHold() external view override returns (uint8) {
        return _threshHold;
    }

    function verifyExchange(bytes32 hash_, Types.Signature[] calldata signs_) external view override returns (bool) {
        // NotEnoughOracles
        uint256 length = signs_.length;
        if (length < _threshHold) return false;

        address recoveredAddress;
        address lastAddress;
        bytes32 digest = _hashTypedDataV4(hash_);

        for (uint256 i; i < length; ) {
            (recoveredAddress, ) = ECDSAUpgradeable.tryRecover(digest, signs_[i].v, signs_[i].r, signs_[i].s);

            // DuplicateSignatures
            if (recoveredAddress != address(0) && recoveredAddress < lastAddress) return false;

            // InvalidOracle
            if (!hasRole(SIGNER_ROLE, recoveredAddress)) return false;

            lastAddress = recoveredAddress;

            unchecked {
                ++i;
            }
        }

        return true;
    }

    uint256[49] private __gap;
}
