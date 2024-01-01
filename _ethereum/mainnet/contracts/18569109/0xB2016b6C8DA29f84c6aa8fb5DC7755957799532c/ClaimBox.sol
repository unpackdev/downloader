// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

import "./TimeLockOwnable.sol";

import "./IGenesisPen.sol";

contract ClaimBox is ReentrancyGuard, Pausable, TimeLockOwnable {
    using ECDSA for bytes32;

    address public immutable core;
    address public signerAddress = 0x8D515254817451dB904dA8B64AE9a1eF8F9a5aef;
    mapping(uint256 => bool) public nonceUsed;
    constructor(address addr_) TimeLockOwnable(3 days) {
        core = addr_;

    }

    /**
     * @notice it is used to claim a token from the reward box.
     * @param deadline_ The deadline of the claim.
     * @param nonce_ The nonce of the claim.
     * @param hash_ The hash of the claim.
     * @param v v value
     * @param r r value
     * @param s s value
     */
    function claim(
        uint256 deadline_,
        uint256 nonce_,
        bytes32 hash_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused {
        require(tx.origin == msg.sender, "Socrates: Contracts not allowed");
        require(!nonceUsed[nonce_], "Socrates: Nonce already used");
        require(hash_ == keccak256(abi.encodePacked(msg.sender, nonce_, deadline_, block.chainid)), "Socrates: Hash mismatch");
        require(IGenesisPen(core).getRemainingBalance(address(this)) > 0, "Socrates: No more token to mint");
        require(block.timestamp <= deadline_, "Socrates: Mint expired");
        

        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash_)
        );

        require(signerAddress == ecrecover(messageDigest, v, r, s), "Socrates: Signature mismatch");

        nonceUsed[nonce_] = true;

        IGenesisPen(core).authorizedMint(msg.sender, 1);

    }

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    function setSignerAddress(address addr_) external onlyOwner {
        signerAddress = addr_;
    }

}
