// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./ISignatureVerifier.sol";

library ECDSA {

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    
    function ethSignedMessage(bytes32 hashedMessage) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", 
                hashedMessage
            )
        );
    }

}


contract SignatureVerifier is ISignatureVerifier, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using ECDSA for bytes32;

    address public TRUSTED_PARTY;

    mapping(bytes32 => bool) public nonceUsed;

    address private ADMIN_OPERATOR;

    modifier unusedNonce(bytes32 nonce) {
        require(!nonceUsed[nonce], "Nonce being used");
        _;
    }

    function initialize(address _trusted) 
    external
    initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        TRUSTED_PARTY = _trusted;
    }

    function setTrustedParty(address _trusted)
    external
    onlyOwner {
        TRUSTED_PARTY = _trusted;
    }

    function setOperator(address _operator)
    external
    onlyOwner {
        ADMIN_OPERATOR = _operator;
    }    

    function verifyWithdrawTokenFromLand (
        bytes32 nonce,
        address receiver,
        uint256 landId,
        uint256 amount,
        bytes memory signature
    )
    unusedNonce(nonce)
    nonReentrant
    whenNotPaused
    override
    public 
    returns (bool) {
        address signer = keccak256(
            abi.encode(nonce, receiver, landId, amount)
        ).ethSignedMessage().recover(signature);
        require(signer == TRUSTED_PARTY, "Invalid request");
        
        nonceUsed[nonce] = true;
        emit UsedNonce(receiver, nonce, "withdraw token from land");
        return true;
    }

    function verifyWithdrawToken (
        bytes32 nonce,
        address receiver,
        uint256 amount,
        bytes memory signature
    )
    unusedNonce(nonce)
    nonReentrant
    whenNotPaused
    override
    public 
    returns (bool) {
        address signer = keccak256(
            abi.encode(nonce, receiver, amount)
        ).ethSignedMessage().recover(signature);
        require(signer == TRUSTED_PARTY, "Invalid request");
        
        nonceUsed[nonce] = true;
        emit UsedNonce(receiver, nonce, "withdraw token");
        return true;
    }

    function verifyWithdrawEnrich (
        bytes32 nonce,
        address receiver,
        uint256[] memory enrichIds,
        uint256[] memory amounts,
        bytes memory signature
    )
    unusedNonce(nonce)
    nonReentrant
    whenNotPaused
    override
    public 
    returns (bool) {
        address signer = keccak256(
            abi.encode(nonce, receiver, enrichIds, amounts)
        ).ethSignedMessage().recover(signature);
        require(signer == TRUSTED_PARTY, "Invalid request");
        
        nonceUsed[nonce] = true;
        emit UsedNonce(receiver, nonce, "withdraw enrich");
        return true;
    }

    function verifyWithdrawResource (
        bytes32 nonce,
        address receiver,
        uint256[] memory resourceIds,
        uint256[] memory amounts,
        bytes memory signature
    )
    unusedNonce(nonce)
    nonReentrant
    whenNotPaused
    override
    public 
    returns (bool) {
        address signer = keccak256(
            abi.encode(nonce, receiver, resourceIds, amounts)
        ).ethSignedMessage().recover(signature);
        require(signer == TRUSTED_PARTY, "Invalid request");
        
        nonceUsed[nonce] = true;
        emit UsedNonce(receiver, nonce, "withdraw resource");
        return true;
    }

    function verifyClaimLand (
        bytes32 nonce,
        address receiver,
        uint256[] memory nekoId,
        bytes memory signature
    )
    unusedNonce(nonce)
    nonReentrant 
    whenNotPaused
    override
    public 
    returns (bool) {
        address signer = keccak256(
            abi.encode(nonce, receiver, nekoId)
        ).ethSignedMessage().recover(signature);
        require(signer == TRUSTED_PARTY, "Invalid request");
        
        nonceUsed[nonce] = true;
        emit UsedNonce(receiver, nonce, "claim land");
        return true;
    }

    function setUsedNonce(bytes32 nonce) public {
        require(msg.sender == ADMIN_OPERATOR, 'Caller is not admin');
        nonceUsed[nonce] = true;
    }

    uint256[47] private __gap;
}