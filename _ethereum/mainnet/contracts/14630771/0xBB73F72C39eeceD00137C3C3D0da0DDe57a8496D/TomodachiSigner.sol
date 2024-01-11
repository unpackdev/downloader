//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./draft-EIP712Upgradeable.sol";

contract TomodachiSigner is EIP712Upgradeable {
    string private constant SIGNING_DOMAIN = "Tomodachi";
    string private constant SIGNATURE_VERSION = "1";

    struct WhiteList {
        address userAddress;
        bool isReserveList;
        bytes signature;
    }

    function __TomodachiSigner_init() internal initializer {
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
    }

    function getSigner(WhiteList memory tomo) public view returns (address) {
        return _verify(tomo);
    }

    /// @notice Returns a hash of the given rarity, prepared using EIP712 typed data hashing rules.

    function _hash(WhiteList memory tomo) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "WhiteList(address userAddress,bool isReserveList)"
                        ),
                        tomo.userAddress,
                        tomo.isReserveList
                    )
                )
            );
    }

    function _verify(WhiteList memory tomo) internal view returns (address) {
        bytes32 digest = _hash(tomo);
        return ECDSAUpgradeable.recover(digest, tomo.signature);
    }
}
