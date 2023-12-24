// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./IERC1155TokenUriSignatureMintInternal.sol";
import "./ERC1155TokenUriSignatureMintStorage.sol";
import "./ECDSA.sol";
import "./ERC1155BaseInternal.sol";
import "./ERC1155MetadataInternal.sol";

contract ERC1155TokenUriSignatureMintBaseInternal is
    IERC1155TokenUriSignatureMintInternal,
    ERC1155BaseInternal,
    ERC1155MetadataInternal
{
    using ECDSA for bytes32;

    bytes32 internal constant _DOMAIN_SEPARATOR_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 internal constant _MINT_BATCH_URI_TYPEHASH =
        keccak256(
            "MintBatchURI(address to,string[] tokenUris,uint256[] amounts,uint256 nonce,uint256 expiry)"
        );

    function _mintBatchWithTokenUriViaSignature(
        address to,
        string[] calldata tokenUris,
        uint256[] calldata amounts,
        uint256 expiry,
        bytes calldata signature
    ) internal {
        _verifyMintBatchSignature(to, tokenUris, amounts, expiry, signature);
        uint256[] memory ids = _idsFromTokenUris(tokenUris);

        _mintBatch(to, ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            _setTokenURI(ids[i], tokenUris[i]);
        }
    }

    function _setMintSigner(address signer) internal {
        ERC1155TokenUriSignatureMintStorage.Layout
            storage l = ERC1155TokenUriSignatureMintStorage.layout();
        l.mintSigner = signer;
    }

    function _mintSigner() internal view returns (address) {
        return ERC1155TokenUriSignatureMintStorage.layout().mintSigner;
    }

    function _verifyMintBatchSignature(
        address to,
        string[] calldata tokenUris,
        uint256[] calldata amounts,
        uint256 expiry,
        bytes calldata signature
    ) internal {
        if (block.timestamp > expiry)
            revert ERC1155TokenUriSignatureMint__ExpiredDeadline();

        address mintSigner = ERC1155TokenUriSignatureMintStorage
            .layout()
            .mintSigner;
        if (mintSigner == address(0))
            revert ERC1155TokenUriSignatureMint__InvalidSigner();

        uint256 nonce = _getNonceAndIncrement(to);

        bytes32 digest = _calculateDigestForMintBatch(
            to,
            tokenUris,
            amounts,
            nonce,
            expiry
        );

        if (mintSigner != digest.recover(signature))
            revert ERC1155TokenUriSignatureMint__InvalidSignature();
    }

    function _getNonceAndIncrement(address account) internal returns (uint256) {
        ERC1155TokenUriSignatureMintStorage.Layout
            storage l = ERC1155TokenUriSignatureMintStorage.layout();
        return l.nonces[account]++;
    }

    function _nonceForUser(address account) internal view returns (uint256) {
        return ERC1155TokenUriSignatureMintStorage.layout().nonces[account];
    }

    /**
     * @notice return the EIP-712 domain separator unique to contract and chain
     * @return domainSeparator domain separator
     */
    function _DOMAIN_SEPARATOR()
        internal
        view
        returns (bytes32 domainSeparator)
    {
        domainSeparator = ERC1155TokenUriSignatureMintStorage
            .layout()
            .domainSeparators[_chainId()];

        if (domainSeparator == 0x00) {
            domainSeparator = _calculateDomainSeparator();
        }
    }

    /**
     * @notice calculate unique EIP-712 domain separator
     * @return domainSeparator domain separator
     */
    function _calculateDomainSeparator()
        internal
        view
        returns (bytes32 domainSeparator)
    {
        // no need for assembly, running very rarely
        domainSeparator = keccak256(
            abi.encode(
                _DOMAIN_SEPARATOR_TYPEHASH,
                keccak256(bytes("ERC1155TokenUriSignatureMint")), // Name
                keccak256(bytes("1")), // Version
                _chainId(),
                address(this)
            )
        );
    }

    /**
     * @notice get the current chain ID
     * @return chainId chain ID
     */
    function _chainId() private view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    function _calculateDigestForMintBatch(
        address to,
        string[] calldata tokenUris,
        uint256[] calldata amounts,
        uint256 nonce,
        uint256 expiry
    ) internal view returns (bytes32 digest) {
        // array values are encoded as the hash of their contents
        bytes32[] memory hashes = new bytes32[](tokenUris.length);
        for (uint256 i; i < tokenUris.length; i++) {
            hashes[i] = keccak256(bytes(tokenUris[i]));
        }

        bytes32 tokenUrisHash = keccak256(abi.encodePacked(hashes));
        bytes32 amountsHash = keccak256(abi.encodePacked(amounts));

        bytes32 structHash = keccak256(
            abi.encode(
                _MINT_BATCH_URI_TYPEHASH,
                to,
                tokenUrisHash,
                amountsHash,
                nonce,
                expiry
            )
        );

        digest = keccak256(
            abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR(), structHash)
        );
    }

    function _idsFromTokenUris(string[] calldata tokenUris)
        internal
        returns (uint256[] memory ids)
    {
        ids = new uint256[](tokenUris.length);

        ERC1155TokenUriSignatureMintStorage.Layout
            storage l = ERC1155TokenUriSignatureMintStorage.layout();

        for (uint256 i; i < tokenUris.length; i++) {
            bytes32 tokenHash = keccak256(bytes(tokenUris[i]));
            uint256 existingId = l.tokenIdsByUri[tokenHash];

            if (existingId != 0) {
                ids[i] = existingId;
                continue;
            }

            ids[i] = ++l.currentTokenId;
            l.tokenIdsByUri[tokenHash] = ids[i];
        }
    }
}
