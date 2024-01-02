// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ECDSAUpgradeable.sol";

contract SignatureVerification_V2 {
    event SignatureUsed(
        address sender,
        address recipient,
        uint256 rndAmount,
        uint256 vestingStartTime,
        uint256 vestingPeriod,
        uint256 cliffPeriod,
        uint8 nftLevel,
        uint256 timestamp,
        uint256 chainId,
        bytes signature
    );
    address private systemAddress;
    mapping(bytes => bool) private _usedSignatures;

    /// @notice Redeem a signature
    /// @param recipient The address of the recipient
    /// @param rndAmount The amount of tokens to be redeemed
    /// @param vestingStartTime The timestamp of the signature
    /// @param vestingPeriod The timestamp of the signature
    /// @param cliffPeriod The timestamp of the signature
    /// @param nftLevel The timestamp of the signature
    /// @param timestamp The timestamp of the signature
    /// @param signature The signature to be redeemed
    /// @return True if the signature is valid
    function _redeemSignature(
        address recipient,
        uint256 rndAmount,
        uint256 vestingStartTime,
        uint256 vestingPeriod,
        uint256 cliffPeriod,
        uint8 nftLevel,
        uint256 timestamp,
        bytes memory signature,
        address signerAddress
    ) internal returns (bool) {
        // Check the length of the signature
        require(signature.length == 65, "VC: Invalid signature length");
        // Check if timestamp is valid and not older than 1 hour
        require(
            timestamp >= block.timestamp && timestamp <= block.timestamp + 3600,
            "VC: Signature has expired"
        );
        // Check if the signature has been used before
        require(!_usedSignatures[signature], "VC: Signature already used");
        // Build the hash and check the sig
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                msg.sender,
                recipient,
                rndAmount,
                vestingStartTime,
                vestingPeriod,
                cliffPeriod,
                nftLevel,
                timestamp,
                block.chainid
            )
        );
        // Append the EIP-191 version byte
        bytes32 signedHash = ECDSAUpgradeable.toEthSignedMessageHash(msgHash);
        // Recover the signer address and check if it matches the system address
        require(
            ECDSAUpgradeable.recover(signedHash, signature) == signerAddress,
            "VC: Signature not valid"
        );
        // Set the signature as used
        _usedSignatures[signature] = true;
        // Emit the signature
        emit SignatureUsed(
            msg.sender,
            recipient,
            rndAmount,
            vestingStartTime,
            vestingPeriod,
            cliffPeriod,
            nftLevel,
            timestamp,
            block.chainid,
            signature
        );

        return true;
    }
}
