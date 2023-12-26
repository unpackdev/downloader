// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import "./EIP712.sol";
import "./PoppetErrorsAndEvents.sol";

contract PoppetEIP712 is EIP712, PoppetErrorsAndEvents {
    struct MintKey {
        address wallet;
        uint256 threadId;
        uint256 nonce;
    }

    struct JournalKey {
        uint256 tokenId;
        string ipfs_cid;
    }

    struct SwapKey {
        address wallet;
        uint256 tokenId;
        uint256[] remove;
        uint256[] add;
        uint256[] removeC;
        uint256[] addC;
        uint256 nonce;
    }

    struct SwapPermissionKey {
        address wallet;
        uint256 fromPoppet;
        uint256 toPoppet;
        uint256[] remove;
        uint256[] add;
        uint256[] removeC;
        uint256[] addC;
        uint256 nonce;
    }

    struct SwapPermissionMasterKey {
        bytes signatureA;
        bytes signatureB;
        uint256 nonce;
    }

    struct RevealKey {
        address wallet;
        uint256 tokenId;
        uint256[] poppet_accessories;
        uint256[] bonus_accessories;
        uint256 free_poppets;
        uint256 nonce;
    }

    struct Amounts {
        uint256[] removeAmounts;
        uint256[] addAmounts;
        uint256[] removeCAmounts;
        uint256[] addCAmounts;
    }

    mapping(bytes => bool) private _signature_used;

    bytes32 private constant MINTKEY_TYPE_HASH =
        keccak256("MintKey(address wallet,uint256 threadId,uint256 nonce)");

    bytes32 private constant JOURNALKEY_TYPE_HASH =
        keccak256("JournalKey(uint256 tokenId,string ipfs_cid)");

    bytes32 private constant SWAPKEY_TYPE_HASH =
        keccak256(
            "SwapKey(address wallet,uint256 tokenId,uint256[] remove,uint256[] add,uint256[] removeC,uint256[] addC,uint256 nonce)"
        );

    bytes32 private constant SWAP_PERMISSIONKEY_TYPE_HASH =
        keccak256(
            "SwapPermissionKey(address wallet,uint256 fromPoppet,uint256 toPoppet,uint256[] remove,uint256[] add,uint256[] removeC,uint256[] addC,uint256 nonce)"
        );

    bytes32 private constant SWAP_PERMISSION_MASTERKEY_TYPE_HASH =
        keccak256(
            "SwapPermissionMasterKey(bytes signatureA,bytes signatureB,uint256 nonce)"
        );

    bytes32 private constant REVEALKEY_TYPE_HASH =
        keccak256(
            "RevealKey(address wallet,uint256 tokenId,uint256[] poppet_accessories,uint256[] bonus_accessories,uint256 free_poppets,uint256 nonce)"
        );

    address private _signer;

    constructor(string memory name_, address signer_) EIP712(name_, "1") {
        _setSigner(signer_);
    }

    function _setSigner(address signer) internal {
        _signer = signer;
    }

    function _markUsed(bytes calldata signature) internal {
        _signature_used[signature] = true;
    }

    function verifyMintKey(
        bytes calldata signature,
        address wallet,
        uint256 threadId,
        uint256 nonce
    ) internal returns (bool) {
        if (_signature_used[signature]) {
            revert SignatureAlreadyUsed();
        }

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(MINTKEY_TYPE_HASH, wallet, threadId, nonce))
        );

        if (ECDSA.recover(digest, signature) == _signer) {
            _signature_used[signature] = true;
            return true;
        }
        revert InvalidSignature();
    }

    function verifySwapKey(
        bytes calldata signature,
        SwapKey calldata swapKey,
        address wallet
    ) internal returns (bool) {
        if (_signature_used[signature]) {
            revert SignatureAlreadyUsed();
        }

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    SWAPKEY_TYPE_HASH,
                    wallet,
                    swapKey.tokenId,
                    keccak256(abi.encodePacked(swapKey.remove)),
                    keccak256(abi.encodePacked(swapKey.add)),
                    keccak256(abi.encodePacked(swapKey.removeC)),
                    keccak256(abi.encodePacked(swapKey.addC)),
                    swapKey.nonce
                )
            )
        );

        if (ECDSA.recover(digest, signature) == _signer) {
            _signature_used[signature] = true;
            return true;
        }
        revert InvalidSignature();
    }

    function verifySwapPermissionKey(
        bytes calldata signature,
        SwapPermissionKey calldata swapPermissionKey,
        address wallet
    ) internal returns (bool) {
        if (_signature_used[signature]) {
            revert SignatureAlreadyUsed();
        }

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    SWAP_PERMISSIONKEY_TYPE_HASH,
                    swapPermissionKey.wallet,
                    swapPermissionKey.fromPoppet,
                    swapPermissionKey.toPoppet,
                    keccak256(abi.encodePacked(swapPermissionKey.remove)),
                    keccak256(abi.encodePacked(swapPermissionKey.add)),
                    keccak256(abi.encodePacked(swapPermissionKey.removeC)),
                    keccak256(abi.encodePacked(swapPermissionKey.addC)),
                    swapPermissionKey.nonce
                )
            )
        );

        if (ECDSA.recover(digest, signature) == wallet) {
            _signature_used[signature] = true;
            return true;
        }

        revert InvalidSignature();
    }

    function verifySwapPermissionMasterKey(
        bytes calldata signature,
        SwapPermissionMasterKey calldata swapPermissionMasterKey
    ) internal returns (bool) {
        if (_signature_used[signature]) {
            revert SignatureAlreadyUsed();
        }

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    SWAP_PERMISSION_MASTERKEY_TYPE_HASH,
                    keccak256(
                        abi.encodePacked(swapPermissionMasterKey.signatureA)
                    ),
                    keccak256(
                        abi.encodePacked(swapPermissionMasterKey.signatureB)
                    ),
                    swapPermissionMasterKey.nonce
                )
            )
        );

        if (ECDSA.recover(digest, signature) == _signer) {
            _signature_used[signature] = true;
            return true;
        }
        revert InvalidSignature();
    }

    function verifyJournalKey(
        bytes calldata signature,
        uint256 tokenId,
        string calldata ipfs_cid
    ) internal returns (bool) {
        if (_signature_used[signature]) {
            revert SignatureAlreadyUsed();
        }

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    JOURNALKEY_TYPE_HASH,
                    tokenId,
                    keccak256(abi.encodePacked(bytes(ipfs_cid)))
                )
            )
        );

        if (ECDSA.recover(digest, signature) == _signer) {
            _signature_used[signature] = true;
            return true;
        }

        revert InvalidSignature();
    }

    function verifyRevealKey(
        bytes calldata signature,
        address wallet,
        uint256 tokenId,
        uint256[] calldata poppet_accessories,
        uint256[] calldata bonus_accessories,
        uint256 free_poppets,
        uint256 nonce
    ) internal returns (bool) {
        if (_signature_used[signature]) {
            revert SignatureAlreadyUsed();
        }

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    REVEALKEY_TYPE_HASH,
                    wallet,
                    tokenId,
                    keccak256(abi.encodePacked(poppet_accessories)),
                    keccak256(abi.encodePacked(bonus_accessories)),
                    free_poppets,
                    nonce
                )
            )
        );

        if (ECDSA.recover(digest, signature) == _signer) {
            _signature_used[signature] = true;
            return true;
        }

        revert InvalidSignature();
    }
}
