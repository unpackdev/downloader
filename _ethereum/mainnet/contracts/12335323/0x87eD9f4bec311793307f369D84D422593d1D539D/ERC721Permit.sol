// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ECDSA.sol";
import "./Counters.sol";
import "./draft-EIP712.sol";

interface IERC721Permit {
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/**
 * @dev Implementation of the ERC721 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC721 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC721-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
abstract contract ERC721Permit is ERC721, IERC721Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping (address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC721 token name.
     */
    constructor(string memory name) EIP712(name, "1") {
    }

    /**
     * @dev See {IERC721Permit-permit}.
     */
    function permit(address owner, address spender, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {

        address tokenOwner = ownerOf(tokenId);
        require(spender != tokenOwner, "ERC721Permit: approval to current owner");
        require(tokenOwner == owner || isApprovedForAll(tokenOwner, owner),
            "ERC721Permit: approve signer is not owner nor approved for all"
        );

        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC721Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                tokenId,
                _nonces[owner].current(),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC721Permit: invalid signature");

        _nonces[owner].increment();
        super._approve(spender, tokenId);
    }

    /**
     * @dev See {IERC721Permit-nonces}.
     */
    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC721Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function getDigest(bytes32 structHash) public view returns (bytes32) {
        return _hashTypedDataV4(structHash);
    }
}

