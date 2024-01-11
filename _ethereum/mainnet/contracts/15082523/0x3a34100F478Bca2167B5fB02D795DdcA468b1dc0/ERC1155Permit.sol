// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./ECDSA.sol";
import "./IERC1155Permit.sol";

abstract contract ERC1155Permit is ERC1155 {
    mapping(address => uint256) private _nonces;

    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 deadline,uint256 nonce)");

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 private constant VERSION_HASH = keccak256("1");
    bytes32 private constant NAME_HASH = keccak256("ERC1155Permit");

    function permit(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp < deadline, "ERC1155Permit: expired deadline");

        bytes32 hashStruct = keccak256(
            abi.encode(PERMIT_TYPEHASH, owner, spender, deadline, _nonces[owner])
        );

        bytes32 digest = keccak256(abi.encodePacked(uint16(0x1901), _hashDomain(), hashStruct));
        address signer = ECDSA.recover(digest, v, r, s);
        require(signer == owner, "ERC1155Permit: invalid signature");

        _nonces[signer]++;
        _setApprovalForAll(signer, spender, true);
    }

    function nonceOf(address account) external view returns (uint256) {
        return _nonces[account];
    }

    function _hashDomain() private view returns (bytes32) {
        uint256 chainId;

        assembly {
            chainId := chainid()
        }

        return
            keccak256(
                abi.encode(EIP712_DOMAIN_TYPEHASH, NAME_HASH, VERSION_HASH, chainId, address(this))
            );
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155Permit).interfaceId || super.supportsInterface(interfaceId);
    }
}
