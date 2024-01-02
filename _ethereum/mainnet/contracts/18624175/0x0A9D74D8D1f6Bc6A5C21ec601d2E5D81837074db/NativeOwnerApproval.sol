//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "./EIP712Base.sol";
import "./Ownable.sol";


contract NativeOwnerApproval is EIP712Base, Ownable {
    bytes32 private constant OWNER_APPROVAL_TYPEHASH =
        keccak256(bytes("OwnerApproval(uint256 nonce,address from,bytes userData)"));
    mapping(address => uint256) nonces;

    /*
     * Owner Approval structure.
     */
    struct OwnerApproval {
        uint256 nonce;
        address from;
        bytes userData;
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function checkOwnerApproval(
        bytes memory userData,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal {
        OwnerApproval memory ownerApprovalTx = OwnerApproval({
            nonce: nonces[msg.sender],
            from: msg.sender,
            userData: userData
        });
        require(verify(owner(), ownerApprovalTx, sigR, sigS, sigV), "Signer and signature do not match");

        // increase nonce for user (to avoid re-use)
        nonces[msg.sender] = nonces[msg.sender] + 1;
    }

    function hashOwnerApproval(OwnerApproval memory ownerApprovalTx) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(OWNER_APPROVAL_TYPEHASH, ownerApprovalTx.nonce, ownerApprovalTx.from, keccak256(ownerApprovalTx.userData))
            );
    }

    function verify(
        address signer,
        OwnerApproval memory ownerApprovalTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeOwnerApproval: INVALID_SIGNER");
        return signer == ecrecover(toTypedMessageHash(hashOwnerApproval(ownerApprovalTx)), sigV, sigR, sigS);
    }
}