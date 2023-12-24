// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./ECDSA.sol";
import "./MessageHashUtils.sol";
import "./EIP712.sol";
import "./ERC20Upgradeable.sol";
import "./Controllable.sol";

abstract contract Mintable is Controllable, EIP712, ERC20Upgradeable {
    error ProofWasUsed();

    event Mint(
        address indexed minter,
        address indexed to,
        uint256 indexed amount
    );

    // keccak256("mintByAuthorization(uint256 amount,bytes32 proofBlockHash,bytes32 proofTxnHash,uint256[] gluwaNonces,uint256[] expiries,bytes[] signature)");
    bytes32 private constant _MINTBYAUTHORIZATION_TYPEHASH =
        0xc55f05749175b4ba324db46e3b27cb9e05ab693cb666c1a026cc96deb68d4cd9;

    uint8 private _mintingAuthorizationThreshold;

    mapping(bytes32 => uint256) private _mintingRecord;

    function __Mintable_init_unchained(
        uint8 mintingAuthorizationThreshold_
    ) internal onlyInitializing {
        _mintingAuthorizationThreshold = mintingAuthorizationThreshold_;
    }

    /**
     * @dev Allow the Governance role to mint tokens for a account
     */
    function mint(
        address receiver,
        uint256 amount,
        bytes32 proofBlockHash,
        bytes32 proofTxnHash
    ) external virtual onlyOperator returns (bool) {
        _logMintingRecord(amount, proofBlockHash, proofTxnHash);
        _mint(receiver, amount);
        emit Mint(_msgSender(), receiver, amount);
        return true;
    }

    function setMintingAuthorizationThreshold(
        uint8 newThreshold
    ) external onlyOperator {
        require(newThreshold >= 2, "Mintable: new threshold is too small");
        _mintingAuthorizationThreshold = newThreshold;
    }

    function getMintingAuthorizationThreshold() external view returns (uint8) {
        return _mintingAuthorizationThreshold;
    }

    function mintByAuthorization(
        address receiver,
        uint256 amount,
        bytes32 proofBlockHash,
        bytes32 proofTxnHash,
        uint256[] calldata gluwaNonces,
        uint256[] calldata expiries,
        bytes[] calldata signatures
    ) private returns (bool) {
        uint256 numOfSig = expiries.length;
        require(
            numOfSig >= _mintingAuthorizationThreshold,
            "Mintable: not enough signatures"
        );
        for (uint256 i; i < numOfSig; ) {
            require(
                receiver ==
                    _verifySignature(
                        receiver,
                        amount,
                        proofBlockHash,
                        proofTxnHash,
                        gluwaNonces[i],
                        expiries[i],
                        signatures[i]
                    ),
                "Mintable: receiver mismatch"
            );
            unchecked {
                ++i;
            }
        }
        _logMintingRecord(amount, proofBlockHash, proofTxnHash);
        _mint(receiver, amount);
        emit Mint(_msgSender(), receiver, amount);
        return true;
    }

    function mintedAmountByProof(
        bytes32 proofBlockHash,
        bytes32 proofTxnHash
    ) external view returns (uint256) {
        return _mintingRecord[_generateProof(proofBlockHash, proofTxnHash)];
    }

    function _logMintingRecord(
        uint256 amount,
        bytes32 proofBlockHash,
        bytes32 proofTxnHash
    ) private {
        bytes32 proof = _generateProof(proofBlockHash, proofTxnHash);
        if (_mintingRecord[proof] > 0) revert ProofWasUsed();
        _mintingRecord[proof] = amount;
    }

    function _generateProof(
        bytes32 proofBlockHash,
        bytes32 proofTxnHash
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(proofBlockHash, proofTxnHash));
    }

    function _verifySignature(
        address receiver,
        uint256 amount,
        bytes32 proofBlockHash,
        bytes32 proofTxnHash,
        uint256 gluwaNonce,
        uint256 expiry,
        bytes calldata signature
    ) private view returns (address) {
        require(
            expiry >= block.timestamp,
            "ERC20StakedVotesUpgradeable: Sig is expired"
        );
        return
            ECDSA.recover(
                MessageHashUtils.toEthSignedMessageHash(_hashTypedDataV4(
                    keccak256(
                        abi.encode(
                            _MINTBYAUTHORIZATION_TYPEHASH,
                            receiver,
                            amount,
                            proofBlockHash,
                            proofTxnHash,
                            gluwaNonce,
                            expiry
                        )
                    )
                )),
                signature
            );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
