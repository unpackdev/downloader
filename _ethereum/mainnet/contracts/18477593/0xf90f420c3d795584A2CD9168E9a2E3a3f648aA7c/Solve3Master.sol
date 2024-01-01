//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./MasterStorage.sol";
import "./ISolve3Master.sol";
import "./IERC20.sol";
import "./Initializable.sol";

/// @title Solve3Master
/// @author 0xKurt
/// @notice Solve3 caster contract to verify proofs
contract Solve3Master is ISolve3Master, Initializable, MasterStorage {

    // ============ Initializer ============
    /// @notice Initialize the contract
    /// @param _signer the Solve3 signer address
    function initialize(address _signer) external initializer {
        if (owner != address(0)) revert TransferOwnershipFailed();

        _transferOwnership(msg.sender);
        _setSigner(_signer, true);

        // EIP 712
        // https://eips.ethereum.org/EIPS/eip-712
        DOMAIN_SEPARATOR = _hash(
            EIP712Domain({
                name: "Solve3",
                version: "1",
                chainId: block.chainid,
                verifyingContract: address(this)
            })
        );
    }

    // ============ Views ============

    /// @notice The nonce of an account is used to prevent replay attacks
    /// @param _account the account to get the nonce
    function getNonce(address _account)
        external
        view
        override
        returns (uint256)
    {
        return nonces[_account];
    }

    /// @notice Get the actual timestamp and nonce of an account
    /// @param _account the account to get nonce for
    function getTimestampAndNonce(address _account)
        external
        view
        returns (uint256, uint256)
    {
        return (block.timestamp, nonces[_account]);
    }

    /// @notice Get the signer status of an account
    /// @param _account the account to get signer status for
    function isSigner(address _account) external view returns (bool) {
        return signer[_account];
    }

    // ============ Owner Functions ============

    /// @notice Set the signer status of an account
    /// @param _account The account to set signer status for
    /// @param _flag The signer status to set
    function setSigner(address _account, bool _flag) external {
        _onlyOwner();
        _setSigner(_account, _flag);
    }

    /// @notice Set the signer status of an account
    /// @param _account The account to set signer status for
    /// @param _flag The signer status to set
    function _setSigner(address _account, bool _flag) internal {
        signer[_account] = _flag;
        emit SignerChanged(_account, _flag);
    }

    /// @notice Transfer ownership of the contract
    /// @param _newOwner The new owner of the contract
    function transferOwnership(address _newOwner) external {
        _onlyOwner();
        _transferOwnership(_newOwner);
    }

    /// @notice Transfer ownership of the contract
    /// @param _newOwner The new owner of the contract
    function _transferOwnership(address _newOwner) internal {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /// @notice Recover ERC20 tokens
    /// @param _token The token to recover
    function recoverERC20(address _token) external {
        _onlyOwner();
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, balance);
    }

    // ============ EIP 712 Functions ============

    /// @notice Verify a proof
    /// @param _proof The proof to verify
    /// @return account The account of the proof
    /// @return timestamp The timestamp of the proof
    /// @return verified The verification status of the proof
    function verifyProof(bytes calldata _proof)
        external
        returns (
            address account,
            uint256 timestamp,
            bool verified
        )
    {
        return _verifyProof(_proof);
    }

    /// @notice Verify a proof
    /// @param _proof The proof to verify
    /// @return account The account of the proof
    /// @return timestamp The timestamp of the proof
    /// @return verified The verification status of the proof
    function _verifyProof(bytes calldata _proof)
        internal
        returns (
            address,
            uint256,
            bool
        )
    {
        Proof memory proof = abi.decode(_proof, (Proof));
        ProofData memory proofData = proof.data;
        bool verified;
        address signerAddress;

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, _hash(proofData))
        );

        signerAddress = ecrecover(digest, proof.v, proof.r, proof.s);
        
        if (
            nonces[proofData.account] == proofData.nonce &&
            proofData.timestamp < block.timestamp &&
            signer[signerAddress] &&
            msg.sender == proofData.destination
        ) {
            verified = true;
            nonces[proofData.account] += 1;
        } else {
          revert Solve3MasterNotVerified();
        }

        return (proofData.account, proofData.timestamp, verified);
    }

    // ============ Hash Functions ============

    /// @notice Hash the EIP712 domain
    /// @param _eip712Domain The EIP712 domain to hash
    /// @return The hash of the EIP712 domain
    function _hash(EIP712Domain memory _eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(_eip712Domain.name)),
                    keccak256(bytes(_eip712Domain.version)),
                    _eip712Domain.chainId,
                    _eip712Domain.verifyingContract
                )
            );
    }

    /// @notice Hash the proof data
    /// @param _data The proof data to hash
    /// @return The hash of the proof data
    function _hash(ProofData memory _data) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PROOFDATA_TYPEHASH,
                    _data.account,
                    _data.nonce,
                    _data.timestamp,
                    _data.destination
                )
            );
    }

    // ============ Modifier like functions ============

    /// @notice Check if the caller is the owner
    function _onlyOwner() internal view {
        if (msg.sender != owner) revert NotOwner();
    }

    // ============ Errors ============

    error TransferOwnershipFailed();
    error NotOwner();
    error Solve3MasterNotVerified();

    // ============ Events ============

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    event SignerChanged(address indexed account, bool flag);
}
