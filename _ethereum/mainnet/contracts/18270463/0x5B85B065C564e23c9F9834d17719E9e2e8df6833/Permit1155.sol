// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./OwnableUpgradeable.sol";
import "./IERC1155.sol";
import "./SignatureChecker.sol";
import "./EIP712WithNonce.sol";
import "./PermitTypes.sol";

abstract contract Permit1155 is OwnableUpgradeable, EIP712WithNonce {
    // keccak256(
    //     "Permit1155(address registry,uint256 tokenId,address from,address to,uint256 value,address receiverFeeAddr,uint256 platformFee,uint256 ownerFee,uint256 creatorFee,address creatorFeeAddr,uint256 nonce,uint256 deadline,uint256 salt,uint32 metadata,bytes data)"
    // );
    bytes32 public constant permit1155TypeHash = 0x921db050e8046dbf3cf3a2d0e719a2fb76deac3ca0e3b33ebc7c811693c49ed0;

    /**
     * @notice Internal method to transfer erc1155 token with signature.
     * @dev The signature can be provisioned by the nft owner or GOTCHA.
     * @param   data The Transfer1155WithSignData
     */
    function transfer1155WithSign(Transfer1155WithSignData memory data) internal {
        require(data.value > 0, "Permit1155:: The value must be a non-zero integer");
        require(block.timestamp <= data.deadline, "Permit1155:: Deadline reached");
        EIP712WithNonce._verifyAndConsumeNonce(data.from, data.nonce);
        bytes32 structHash = getStructHash(data);
        bytes32 hash = _hashTypedDataV4(structHash);
        require(
            SignatureChecker.isValidSignatureNow(owner(), hash, data.signature) ||
                SignatureChecker.isValidSignatureNow(data.from, hash, data.signature),
            "Permit1155:: Invalid signature"
        );

        IERC1155(data.assetIdentifierData.registry).safeTransferFrom(
            data.from,
            data.to,
            data.assetIdentifierData.tokenId,
            data.value,
            data.data
        );
    }

    function getStructHash(Transfer1155WithSignData memory data) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    permit1155TypeHash,
                    data.assetIdentifierData,
                    data.from,
                    data.to,
                    data.value,
                    data.feeData,
                    data.nonce,
                    data.deadline,
                    data.salt,
                    data.metadata,
                    keccak256(data.data)
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
