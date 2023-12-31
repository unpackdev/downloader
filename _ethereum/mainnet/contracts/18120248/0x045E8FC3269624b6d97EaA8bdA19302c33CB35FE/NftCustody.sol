// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract NftCustody is IERC721Receiver, Ownable {
    ERC721 public immutable erc721Contract;

    string public name;

    string public version;

    address public withdrawRequestVerifier;

    bytes32 public immutable eip712DomainSeparator;

    bytes32 public immutable WITHDRAW_TYPEHASH =
        keccak256("withdraw(uint256 tokenId,address recipient)");

    constructor(
        address _erc721Address,
        string memory _name,
        string memory _version,
        address _withdrawRequestVerifier
    ) {
        require(_erc721Address != address(0));
        require(_withdrawRequestVerifier != address(0));

        erc721Contract = ERC721(_erc721Address);
        name = _name;
        version = _version;
        withdrawRequestVerifier = _withdrawRequestVerifier;

        eip712DomainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
    }

    function withdraw(
        uint256 tokenId,
        address recipient,
        bytes calldata signature
    ) external {
        confirmSignature(tokenId, recipient, signature);
        erc721Contract.safeTransferFrom(address(this), recipient, tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function confirmSignature(
        uint256 tokenId,
        address recipient,
        bytes calldata signature
    ) public view {
        bytes32 digest = toTypedMintDataHash(tokenId, recipient);
        address signerAddress = ECDSA.recover(digest, signature);
        require(signerAddress != address(0));
        require(
            signerAddress == withdrawRequestVerifier,
            "Signature not valid."
        );
    }

    function toTypedMintDataHash(
        uint256 tokenId,
        address recipient
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(WITHDRAW_TYPEHASH, tokenId, recipient)
        );
        return ECDSA.toTypedDataHash(eip712DomainSeparator, structHash);
    }
}
