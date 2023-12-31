// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./OwnableUpgradeable.sol";
import "./SignatureChecker.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EIP712WithNonce.sol";
import "./PermitTypes.sol";

abstract contract Permit20 is OwnableUpgradeable, EIP712WithNonce {
    using SafeERC20 for IERC20;

    // keccak256(
    //     "Permit20(address registry,address from,address to,uint256 value,uint256 platformFee,uint256 creatorFee,address creatorFeeAddr,uint256 nonce,uint256 deadline,uint32 metadata)"
    // );
    bytes32 public constant permit20TypeHash = 0xfd33a3fb8164b74914790841181493fe92895511c79e114fb4e569bbac523bd7;

    /**
     * @notice Internal method to transfer erc20 token with signature.
     * @dev The signature can be provisioned by owner and GOTCHA.
     * @param   registry Address
     * @param   from Address
     * @param   to Address.
     * @param   receiverFee Receiver fee value.
     * @param   feeData Transfer20 fee data.
     * @param   nonce Nonce value.
     * @param   deadline Deadline Timestamp.
     * @param   metadata Metadata information.
     * @param   signatures Signatures. position0 owner
     *                                 position1 paragon
     */
    function transfer20WithSign(
        address registry,
        address from,
        address to,
        uint256 receiverFee,
        Transfer20FeeData memory feeData,
        uint256 nonce,
        uint256 deadline,
        uint32 metadata,
        bytes[2] calldata signatures
    ) internal {
        require(block.timestamp <= deadline, "Permit20: Deadline reached");

        EIP712WithNonce._verifyAndConsumeNonce(from, nonce);
        bytes32 structHash = keccak256(
            abi.encode(permit20TypeHash, registry, from, to, receiverFee, feeData, nonce, deadline, metadata)
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        require(
            SignatureChecker.isValidSignatureNow(from, hash, signatures[0]) &&
                SignatureChecker.isValidSignatureNow(owner(), hash, signatures[1]),
            "Permit20: Invalid signature"
        );

        IERC20(registry).safeTransferFrom(from, to, receiverFee);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
