// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.15;

import "./Create2.sol";

/// @title ClonesWithImmutableArgs
/// @author wighawag, zefram.eth, Saw-mon & Natalie, wminshew
/// @notice Enables creating clone contracts with immutable args
library ClonesWithImmutableArgs {
    // abi.encodeWithSignature("CreateFail()")
    uint256 private constant _CREATE_FAIL_ERROR_SIG =
        0xebfef18800000000000000000000000000000000000000000000000000000000;

    // abi.encodeWithSignature("IdentityPrecompileFailure()")
    uint256 private constant _IDENTITY_PRECOMPILE_ERROR_SIG =
        0x3a008ffa00000000000000000000000000000000000000000000000000000000;

    uint256 private constant _CUSTOM_ERROR_SIG_PTR = 0x0;

    uint256 private constant _CUSTOM_ERROR_LENGTH = 0x4;

    uint256 private constant _BOOTSTRAP_LENGTH = 0x3f; // 63 (43 instructions + 20 for implementation address)

    /// @notice Creates a clone proxy of the implementation contract with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(address implementation, bytes memory data) internal returns (address instance) {
        (uint256 creationPtr, uint256 creationSize) = _getCreationCode(implementation, data);

        assembly ("memory-safe") {
            instance := create(0, creationPtr, creationSize)

            // if the create failed, the instance address won't be set
            if iszero(instance) {
                mstore(_CUSTOM_ERROR_SIG_PTR, _CREATE_FAIL_ERROR_SIG)
                revert(_CUSTOM_ERROR_SIG_PTR, _CUSTOM_ERROR_LENGTH)
            }
        }
    }

    /// @notice Creates a clone proxy of the implementation contract with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param salt The salt for create2
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function cloneDeterministic(
        address implementation,
        bytes32 salt,
        bytes memory data
    ) internal returns (address payable instance) {
        (uint256 creationPtr, uint256 creationSize) = _getCreationCode(implementation, data);

        assembly ("memory-safe") {
            instance := create2(0, creationPtr, creationSize, salt)

            // if the create failed, the instance address won't be set
            if iszero(instance) {
                mstore(_CUSTOM_ERROR_SIG_PTR, _CREATE_FAIL_ERROR_SIG)
                revert(_CUSTOM_ERROR_SIG_PTR, _CUSTOM_ERROR_LENGTH)
            }
        }
    }

    /// @notice Predicts the address where a deterministic clone of implementation will be deployed
    /// @param implementation The implementation contract to clone
    /// @param salt The salt for create2
    /// @param data Encoded immutable args
    /// @return predicted The predicted address of the created clone exists
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer,
        bytes memory data
    ) internal view returns (address predicted) {
        (uint256 creationPtr, uint256 creationSize) = _getCreationCode(implementation, data);

        bytes32 bytecodeHash;
        assembly ("memory-safe") {
            bytecodeHash := keccak256(creationPtr, creationSize)
        }

        predicted = Create2.computeAddress(salt, bytecodeHash, deployer);
    }

    /// @notice Predicts the address where a deterministic clone of implementation will be deployed
    /// @param implementation The implementation contract to clone
    /// @param salt The salt for create2
    /// @param data Encoded immutable args
    /// @return predicted The predicted address of the created clone exists
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        bytes memory data
    ) internal view returns (address predicted) {
        predicted = predictDeterministicAddress(implementation, salt, address(this), data);
    }

    /// @notice Computes the creation code for a clone with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return ptr The ptr to the clone's bytecode
    /// @return creationSize The size of the clone to be created
    function _getCreationCode(
        address implementation,
        bytes memory data
    ) private view returns (uint256 ptr, uint256 creationSize) {
        // unrealistic for memory ptr or data length to exceed 256 bits
        assembly ("memory-safe") {
            let extraLength := add(mload(data), 2) // +2 bytes for telling how much data there is appended to the call
            creationSize := add(extraLength, _BOOTSTRAP_LENGTH)
            let runSize := sub(creationSize, 0x0a)

            // free memory pointer
            ptr := mload(0x40)

            // -------------------------------------------------------------------------------------------------------------
            // CREATION (10 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // 61 runtime  | PUSH2 runtime (r)     | r                       | –
            // 3d          | RETURNDATASIZE        | 0 r                     | –
            // 81          | DUP2                  | r 0 r                   | –
            // 60 offset   | PUSH1 offset (o)      | o r 0 r                 | –
            // 3d          | RETURNDATASIZE        | 0 o r 0 r               | –
            // 39          | CODECOPY              | 0 r                     | [0 - runSize): runtime code
            // f3          | RETURN                |                         | [0 - runSize): runtime code

            // -------------------------------------------------------------------------------------------------------------
            // RUNTIME (53 bytes + extraLength)
            // -------------------------------------------------------------------------------------------------------------

            // --- copy calldata to memmory ---
            // 36          | CALLDATASIZE          | cds                     | –
            // 3d          | RETURNDATASIZE        | 0 cds                   | –
            // 3d          | RETURNDATASIZE        | 0 0 cds                 | –
            // 37          | CALLDATACOPY          |                         | [0 - cds): calldata

            // --- keep some values in stack ---
            // 3d          | RETURNDATASIZE        | 0                       | [0 - cds): calldata
            // 3d          | RETURNDATASIZE        | 0 0                     | [0 - cds): calldata
            // 3d          | RETURNDATASIZE        | 0 0 0                   | [0 - cds): calldata
            // 3d          | RETURNDATASIZE        | 0 0 0 0                 | [0 - cds): calldata
            // 61 extra    | PUSH2 extra (e)       | e 0 0 0 0               | [0 - cds): calldata

            // --- copy extra data to memory ---
            // 80          | DUP1                  | e e 0 0 0 0             | [0 - cds): calldata
            // 60 0x35     | PUSH1 0x35            | 0x35 e e 0 0 0 0        | [0 - cds): calldata
            // 36          | CALLDATASIZE          | cds 0x35 e e 0 0 0 0    | [0 - cds): calldata
            // 39          | CODECOPY              | e 0 0 0 0               | [0 - cds): calldata, [cds - cds + e): extraData

            // --- delegate call to the implementation contract ---
            // 36          | CALLDATASIZE          | cds e 0 0 0 0           | [0 - cds): calldata, [cds - cds + e): extraData
            // 01          | ADD                   | cds+e 0 0 0 0           | [0 - cds): calldata, [cds - cds + e): extraData
            // 3d          | RETURNDATASIZE        | 0 cds+e 0 0 0 0         | [0 - cds): calldata, [cds - cds + e): extraData
            // 73 addr     | PUSH20 addr           | addr 0 cds+e 0 0 0 0    | [0 - cds): calldata, [cds - cds + e): extraData
            // 5a          | GAS                   | gas addr 0 cds+e 0 0 0 0| [0 - cds): calldata, [cds - cds + e): extraData
            // f4          | DELEGATECALL          | success 0 0             | [0 - cds): calldata, [cds - cds + e): extraData

            // --- copy return data to memory ---
            // 3d          | RETURNDATASIZE        | rds success 0 0         | [0 - cds): calldata, [cds - cds + e): extraData
            // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0 - cds): calldata, [cds - cds + e): extraData
            // 93          | SWAP4                 | 0 rds success 0 rds     | [0 - cds): calldata, [cds - cds + e): extraData
            // 80          | DUP1                  | 0 0 rds success 0 rds   | [0 - cds): calldata, [cds - cds + e): extraData
            // 3e          | RETURNDATACOPY        | success 0 rds           | [0 - rds): returndata, ... the rest might be dirty

            // 60 0x33     | PUSH1 0x33            | 0x33 success 0 rds      | [0 - rds): returndata, ... the rest might be dirty
            // 57          | JUMPI                 | 0 rds                   | [0 - rds): returndata, ... the rest might be dirty

            // --- revert ---
            // fd          | REVERT                |                         | [0 - rds): returndata, ... the rest might be dirty

            // --- return ---
            // 5b          | JUMPDEST              | 0 rds                   | [0 - rds): returndata, ... the rest might be dirty
            // f3          | RETURN                |                         | [0 - rds): returndata, ... the rest might be dirty

            mstore(
                ptr,
                or(
                    // ⎬  ♠︎♠︎♠︎♠︎         ♣︎♣︎         ⎨           -              ♥︎♥︎♥︎♥︎-     ♦︎♦︎      -           >
                    hex"610000_3d_81_600a_3d_39_f3_36_3d_3d_37_3d_3d_3d_3d_610000_80_6035_36_39_36_01_3d_73", // 30 bytes
                    or(shl(0xe8, runSize), shl(0x58, extraLength)) // ♠︎=runSize, ♥︎=extraLength
                )
            )

            mstore(add(ptr, 0x1e), shl(0x60, implementation)) // 20 bytes

            //                        >     -                 ☼☼   -        |
            mstore(add(ptr, 0x32), hex"5a_f4_3d_3d_93_80_3e_6033_57_fd_5b_f3") // 13 bytes

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength := sub(extraLength, 2)

            if iszero(
                staticcall(
                    gas(),
                    0x04, // identity precompile
                    add(data, 0x20), // copy source
                    extraLength,
                    add(ptr, _BOOTSTRAP_LENGTH), // copy destination
                    extraLength
                )
            ) {
                mstore(_CUSTOM_ERROR_SIG_PTR, _IDENTITY_PRECOMPILE_ERROR_SIG)
                revert(_CUSTOM_ERROR_SIG_PTR, _CUSTOM_ERROR_LENGTH)
            }

            mstore(add(add(ptr, _BOOTSTRAP_LENGTH), extraLength), shl(0xf0, add(extraLength, 2)))
        }
    }
}
