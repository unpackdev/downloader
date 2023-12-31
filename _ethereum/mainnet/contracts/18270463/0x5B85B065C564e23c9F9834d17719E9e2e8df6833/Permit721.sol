// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./OwnableUpgradeable.sol";
import "./IERC721.sol";
import "./SignatureChecker.sol";
import "./EIP712WithNonce.sol";
import "./PermitTypes.sol";

abstract contract Permit721 is OwnableUpgradeable, EIP712WithNonce {
    // keccak256(
    //     "Permit721(address registry,uint256 tokenId,address to,address receiverFeeAddr,uint256 platformFee,uint256 ownerFee,uint256 creatorFee,address creatorFeeAddr,uint256 nonce,uint256 deadline,uint256 salt,uint32 metadata)"
    // );
    bytes32 public constant permit721TypeHash = 0x0ede1b946b87e63faf24a99916aa57a8b569a3ad1ff8da11eea21cdc6c1b0563;

    /**
     * @notice Internal method to transfer erc721 token with signature.
     * @dev The signature can be provisioned by the nft owner or GOTCHA.
     * @param   data The Transfer721WithSignData
     */
    function transfer721WithSign(Transfer721WithSignData memory data) internal {
        require(block.timestamp <= data.deadline, "Permit721:: Deadline reached");
        uint256 tokenId = data.assetIdentifierData.tokenId;
        IERC721 registry = IERC721(data.assetIdentifierData.registry);

        address from = registry.ownerOf(tokenId);
        EIP712WithNonce._verifyAndConsumeNonce(from, data.nonce);
        bytes32 structHash = getStructHash(data);
        bytes32 hash = _hashTypedDataV4(structHash);
        require(
            SignatureChecker.isValidSignatureNow(owner(), hash, data.signature) ||
                SignatureChecker.isValidSignatureNow(from, hash, data.signature),
            "Permit721:: Invalid signature"
        );

        registry.safeTransferFrom(from, data.to, tokenId);
    }

    function getStructHash(Transfer721WithSignData memory data) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    permit721TypeHash,
                    data.assetIdentifierData,
                    data.to,
                    data.feeData,
                    data.nonce,
                    data.deadline,
                    data.salt,
                    data.metadata
                )
            );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
