// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/// @notice Class with helper read functions for clone with immutable args.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Clone.sol)
/// @author Adapted from clones with immutable args by zefram.eth, Saw-mon & Natalie
/// (https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args)
abstract contract Clone {
    /// @dev Reads all of the immutable args.
    function _getArgBytes() internal pure returns (bytes memory arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := mload(0x40)
            let length := sub(calldatasize(), add(2, offset)) // 2 bytes are used for the length.
            mstore(arg, length) // Store the length.
            calldatacopy(add(arg, 0x20), offset, length)
            let o := add(add(arg, 0x20), length)
            mstore(o, 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(o, 0x20)) // Allocate the memory.
        }
    }

    /// @dev Reads an immutable arg with type bytes.
    function _getArgBytes(uint256 argOffset, uint256 length)
        internal
        pure
        returns (bytes memory arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := mload(0x40)
            mstore(arg, length) // Store the length.
            calldatacopy(add(arg, 0x20), add(offset, argOffset), length)
            let o := add(add(arg, 0x20), length)
            mstore(o, 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(o, 0x20)) // Allocate the memory.
        }
    }

    /// @dev Reads an immutable arg with type address.
    function _getArgAddress(uint256 argOffset) internal pure returns (address arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(96, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads a uint256 array stored in the immutable args.
    function _getArgUint256Array(uint256 argOffset, uint256 length)
        internal
        pure
        returns (uint256[] memory arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := mload(0x40)
            mstore(arg, length) // Store the length.
            calldatacopy(add(arg, 0x20), add(offset, argOffset), shl(5, length))
            mstore(0x40, add(add(arg, 0x20), shl(5, length))) // Allocate the memory.
        }
    }

    /// @dev Reads a bytes32 array stored in the immutable args.
    function _getArgBytes32Array(uint256 argOffset, uint256 length)
        internal
        pure
        returns (bytes32[] memory arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := mload(0x40)
            mstore(arg, length) // Store the length.
            calldatacopy(add(arg, 0x20), add(offset, argOffset), shl(5, length))
            mstore(0x40, add(add(arg, 0x20), shl(5, length))) // Allocate the memory.
        }
    }

    /// @dev Reads an immutable arg with type bytes32.
    function _getArgBytes32(uint256 argOffset) internal pure returns (bytes32 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @dev Reads an immutable arg with type uint256.
    function _getArgUint256(uint256 argOffset) internal pure returns (uint256 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @dev Reads an immutable arg with type uint248.
    function _getArgUint248(uint256 argOffset) internal pure returns (uint248 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(8, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint240.
    function _getArgUint240(uint256 argOffset) internal pure returns (uint240 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(16, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint232.
    function _getArgUint232(uint256 argOffset) internal pure returns (uint232 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(24, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint224.
    function _getArgUint224(uint256 argOffset) internal pure returns (uint224 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(0x20, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint216.
    function _getArgUint216(uint256 argOffset) internal pure returns (uint216 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(40, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint208.
    function _getArgUint208(uint256 argOffset) internal pure returns (uint208 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(48, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint200.
    function _getArgUint200(uint256 argOffset) internal pure returns (uint200 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(56, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint192.
    function _getArgUint192(uint256 argOffset) internal pure returns (uint192 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(64, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint184.
    function _getArgUint184(uint256 argOffset) internal pure returns (uint184 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(72, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint176.
    function _getArgUint176(uint256 argOffset) internal pure returns (uint176 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(80, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint168.
    function _getArgUint168(uint256 argOffset) internal pure returns (uint168 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(88, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint160.
    function _getArgUint160(uint256 argOffset) internal pure returns (uint160 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(96, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint152.
    function _getArgUint152(uint256 argOffset) internal pure returns (uint152 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(104, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint144.
    function _getArgUint144(uint256 argOffset) internal pure returns (uint144 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(112, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint136.
    function _getArgUint136(uint256 argOffset) internal pure returns (uint136 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(120, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint128.
    function _getArgUint128(uint256 argOffset) internal pure returns (uint128 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(128, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint120.
    function _getArgUint120(uint256 argOffset) internal pure returns (uint120 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(136, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint112.
    function _getArgUint112(uint256 argOffset) internal pure returns (uint112 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(144, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint104.
    function _getArgUint104(uint256 argOffset) internal pure returns (uint104 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(152, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint96.
    function _getArgUint96(uint256 argOffset) internal pure returns (uint96 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(160, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint88.
    function _getArgUint88(uint256 argOffset) internal pure returns (uint88 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(168, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint80.
    function _getArgUint80(uint256 argOffset) internal pure returns (uint80 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(176, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint72.
    function _getArgUint72(uint256 argOffset) internal pure returns (uint72 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(184, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint64.
    function _getArgUint64(uint256 argOffset) internal pure returns (uint64 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(192, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint56.
    function _getArgUint56(uint256 argOffset) internal pure returns (uint56 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(200, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint48.
    function _getArgUint48(uint256 argOffset) internal pure returns (uint48 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(208, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint40.
    function _getArgUint40(uint256 argOffset) internal pure returns (uint40 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(216, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint32.
    function _getArgUint32(uint256 argOffset) internal pure returns (uint32 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(224, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint24.
    function _getArgUint24(uint256 argOffset) internal pure returns (uint24 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(232, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint16.
    function _getArgUint16(uint256 argOffset) internal pure returns (uint16 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(240, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint8.
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(248, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata.
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        /// @solidity memory-safe-assembly
        assembly {
            offset := sub(calldatasize(), shr(240, calldataload(sub(calldatasize(), 2))))
        }
    }
}

/// @notice Simple ERC20 + EIP-2612 implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol)
///
/// @dev Note:
/// - The ERC20 standard allows minting and transferring to and from the zero address,
///   minting and transferring zero tokens, as well as self-approvals.
///   For performance, this implementation WILL NOT revert for such actions.
///   Please add any checks with overrides if desired.
/// - The `permit` function uses the ecrecover precompile (0x1).
///
/// If you are overriding:
/// - NEVER violate the ERC20 invariant:
///   the total sum of all balances must be equal to `totalSupply()`.
/// - Check that the overridden function is actually used in the function you want to
///   change the behavior of. Much of the code has been manually inlined for performance.
abstract contract ERC20 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The total supply has overflowed.
    error TotalSupplyOverflow();

    /// @dev The allowance has overflowed.
    error AllowanceOverflow();

    /// @dev The allowance has underflowed.
    error AllowanceUnderflow();

    /// @dev Insufficient balance.
    error InsufficientBalance();

    /// @dev Insufficient allowance.
    error InsufficientAllowance();

    /// @dev The permit is invalid.
    error InvalidPermit();

    /// @dev The permit has expired.
    error PermitExpired();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when `amount` tokens is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @dev Emitted when `amount` tokens is approved by `owner` to be used by `spender`.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
    uint256 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /// @dev `keccak256(bytes("Approval(address,address,uint256)"))`.
    uint256 private constant _APPROVAL_EVENT_SIGNATURE =
        0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The storage slot for the total supply.
    uint256 private constant _TOTAL_SUPPLY_SLOT = 0x05345cdf77eb68f44c;

    /// @dev The balance slot of `owner` is given by:
    /// ```
    ///     mstore(0x0c, _BALANCE_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let balanceSlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 private constant _BALANCE_SLOT_SEED = 0x87a211a2;

    /// @dev The allowance slot of (`owner`, `spender`) is given by:
    /// ```
    ///     mstore(0x20, spender)
    ///     mstore(0x0c, _ALLOWANCE_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let allowanceSlot := keccak256(0x0c, 0x34)
    /// ```
    uint256 private constant _ALLOWANCE_SLOT_SEED = 0x7f5e9f20;

    /// @dev The nonce slot of `owner` is given by:
    /// ```
    ///     mstore(0x0c, _NONCES_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let nonceSlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 private constant _NONCES_SLOT_SEED = 0x38377508;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev `(_NONCES_SLOT_SEED << 16) | 0x1901`.
    uint256 private constant _NONCES_SLOT_SEED_WITH_SIGNATURE_PREFIX = 0x383775081901;

    /// @dev `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
    bytes32 private constant _DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev `keccak256("1")`.
    bytes32 private constant _VERSION_HASH =
        0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    /// @dev `keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")`.
    bytes32 private constant _PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERC20 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the name of the token.
    function name() public view virtual returns (string memory);

    /// @dev Returns the symbol of the token.
    function symbol() public view virtual returns (string memory);

    /// @dev Returns the decimals places of the token.
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERC20                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the amount of tokens in existence.
    function totalSupply() public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(_TOTAL_SUPPLY_SLOT)
        }
    }

    /// @dev Returns the amount of tokens owned by `owner`.
    function balanceOf(address owner) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Returns the amount of tokens that `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x34))
        }
    }

    /// @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// Emits a {Approval} event.
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and store the amount.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x34), amount)
            // Emit the {Approval} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x2c)))
        }
        return true;
    }

    /// @dev Transfer `amount` tokens from the caller to `to`.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    ///
    /// Emits a {Transfer} event.
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _beforeTokenTransfer(msg.sender, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, caller())
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, caller(), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(msg.sender, to, amount);
        return true;
    }

    /// @dev Transfers `amount` tokens from `from` to `to`.
    ///
    /// Note: Does not update the allowance if it is the maximum uint256 value.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    /// - The caller must have at least `amount` of allowance to transfer the tokens of `from`.
    ///
    /// Emits a {Transfer} event.
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        _beforeTokenTransfer(from, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let from_ := shl(96, from)
            // Compute the allowance slot and load its value.
            mstore(0x20, caller())
            mstore(0x0c, or(from_, _ALLOWANCE_SLOT_SEED))
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)
            // If the allowance is not the maximum uint256 value.
            if add(allowance_, 1) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }
            // Compute the balance slot and load its value.
            mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, from_), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(from, to, amount);
        return true;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EIP-2612                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev For more performance, override to return the constant value
    /// of `keccak256(bytes(name()))` if `name()` will never change.
    function _constantNameHash() internal view virtual returns (bytes32 result) {}

    /// @dev Returns the current nonce for `owner`.
    /// This value is used to compute the signature for EIP-2612 permit.
    function nonces(address owner) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the nonce slot and load its value.
            mstore(0x0c, _NONCES_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Sets `value` as the allowance of `spender` over the tokens of `owner`,
    /// authorized by a signed approval by `owner`.
    ///
    /// Emits a {Approval} event.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        bytes32 nameHash = _constantNameHash();
        //  We simply calculate it on-the-fly to allow for cases where the `name` may change.
        if (nameHash == bytes32(0)) nameHash = keccak256(bytes(name()));
        /// @solidity memory-safe-assembly
        assembly {
            // Revert if the block timestamp is greater than `deadline`.
            if gt(timestamp(), deadline) {
                mstore(0x00, 0x1a15a3cc) // `PermitExpired()`.
                revert(0x1c, 0x04)
            }
            let m := mload(0x40) // Grab the free memory pointer.
            // Clean the upper 96 bits.
            owner := shr(96, shl(96, owner))
            spender := shr(96, shl(96, spender))
            // Compute the nonce slot and load its value.
            mstore(0x0e, _NONCES_SLOT_SEED_WITH_SIGNATURE_PREFIX)
            mstore(0x00, owner)
            let nonceSlot := keccak256(0x0c, 0x20)
            let nonceValue := sload(nonceSlot)
            // Prepare the domain separator.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), nameHash)
            mstore(add(m, 0x40), _VERSION_HASH)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            mstore(0x2e, keccak256(m, 0xa0))
            // Prepare the struct hash.
            mstore(m, _PERMIT_TYPEHASH)
            mstore(add(m, 0x20), owner)
            mstore(add(m, 0x40), spender)
            mstore(add(m, 0x60), value)
            mstore(add(m, 0x80), nonceValue)
            mstore(add(m, 0xa0), deadline)
            mstore(0x4e, keccak256(m, 0xc0))
            // Prepare the ecrecover calldata.
            mstore(0x00, keccak256(0x2c, 0x42))
            mstore(0x20, and(0xff, v))
            mstore(0x40, r)
            mstore(0x60, s)
            let t := staticcall(gas(), 1, 0, 0x80, 0x20, 0x20)
            // If the ecrecover fails, the returndatasize will be 0x00,
            // `owner` will be checked if it equals the hash at 0x00,
            // which evaluates to false (i.e. 0), and we will revert.
            // If the ecrecover succeeds, the returndatasize will be 0x20,
            // `owner` will be compared against the returned address at 0x20.
            if iszero(eq(mload(returndatasize()), owner)) {
                mstore(0x00, 0xddafbaef) // `InvalidPermit()`.
                revert(0x1c, 0x04)
            }
            // Increment and store the updated nonce.
            sstore(nonceSlot, add(nonceValue, t)) // `t` is 1 if ecrecover succeeds.
            // Compute the allowance slot and store the value.
            // The `owner` is already at slot 0x20.
            mstore(0x40, or(shl(160, _ALLOWANCE_SLOT_SEED), spender))
            sstore(keccak256(0x2c, 0x34), value)
            // Emit the {Approval} event.
            log3(add(m, 0x60), 0x20, _APPROVAL_EVENT_SIGNATURE, owner, spender)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero pointer.
        }
    }

    /// @dev Returns the EIP-712 domain separator for the EIP-2612 permit.
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32 result) {
        bytes32 nameHash = _constantNameHash();
        //  We simply calculate it on-the-fly to allow for cases where the `name` may change.
        if (nameHash == bytes32(0)) nameHash = keccak256(bytes(name()));
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Grab the free memory pointer.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), nameHash)
            mstore(add(m, 0x40), _VERSION_HASH)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            result := keccak256(m, 0xa0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL MINT FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Mints `amount` tokens to `to`, increasing the total supply.
    ///
    /// Emits a {Transfer} event.
    function _mint(address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let totalSupplyBefore := sload(_TOTAL_SUPPLY_SLOT)
            let totalSupplyAfter := add(totalSupplyBefore, amount)
            // Revert if the total supply overflows.
            if lt(totalSupplyAfter, totalSupplyBefore) {
                mstore(0x00, 0xe5cfe957) // `TotalSupplyOverflow()`.
                revert(0x1c, 0x04)
            }
            // Store the updated total supply.
            sstore(_TOTAL_SUPPLY_SLOT, totalSupplyAfter)
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, 0, shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(address(0), to, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL BURN FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Burns `amount` tokens from `from`, reducing the total supply.
    ///
    /// Emits a {Transfer} event.
    function _burn(address from, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, from)
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Subtract and store the updated total supply.
            sstore(_TOTAL_SUPPLY_SLOT, sub(sload(_TOTAL_SUPPLY_SLOT), amount))
            // Emit the {Transfer} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, shl(96, from)), 0)
        }
        _afterTokenTransfer(from, address(0), amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL TRANSFER FUNCTIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Moves `amount` of tokens from `from` to `to`.
    function _transfer(address from, address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let from_ := shl(96, from)
            // Compute the balance slot and load its value.
            mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, from_), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(from, to, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL ALLOWANCE FUNCTIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Updates the allowance of `owner` for `spender` based on spent `amount`.
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and load its value.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, owner)
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)
            // If the allowance is not the maximum uint256 value.
            if add(allowance_, 1) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }
        }
    }

    /// @dev Sets `amount` as the allowance of `spender` over the tokens of `owner`.
    ///
    /// Emits a {Approval} event.
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let owner_ := shl(96, owner)
            // Compute the allowance slot and store the amount.
            mstore(0x20, spender)
            mstore(0x0c, or(owner_, _ALLOWANCE_SLOT_SEED))
            sstore(keccak256(0x0c, 0x34), amount)
            // Emit the {Approval} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, shr(96, owner_), shr(96, mload(0x2c)))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HOOKS TO OVERRIDE                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Hook that is called before any transfer of tokens.
    /// This includes minting and burning.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /// @dev Hook that is called after any transfer of tokens.
    /// This includes minting and burning.
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
///
/// @dev Note:
/// - For ETH transfers, please use `forceSafeTransferETH` for DoS protection.
/// - For ERC20s, this implementation won't check that a token has code,
///   responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH that disallows any storage writes.
    uint256 internal constant GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    uint256 internal constant GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // If the ETH transfer MUST succeed with a reasonable gas budget, use the force variants.
    //
    // The regular variants:
    // - Forwards all remaining gas to the target.
    // - Reverts if the target reverts.
    // - Reverts if the current contract has insufficient balance.
    //
    // The force variants:
    // - Forwards with an optional gas stipend
    //   (defaults to `GAS_STIPEND_NO_GRIEF`, which is sufficient for most cases).
    // - If the target reverts, or if the gas stipend is exhausted,
    //   creates a temporary contract to force send the ETH via `SELFDESTRUCT`.
    //   Future compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758.
    // - Reverts if the current contract has insufficient balance.
    //
    // The try variants:
    // - Forwards with a mandatory gas stipend.
    // - Instead of reverting, returns whether the transfer succeeded.

    /// @dev Sends `amount` (in wei) ETH to `to`.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gas(), to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`.
    function safeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer all the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function forceSafeTransferAllETH(address to, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function trySafeTransferAllETH(address to, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have their entire balance approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x00, 0x23b872dd) // `transferFrom(address,address,uint256)`.
            amount := mload(0x60) // The `amount` is already at 0x60. We'll need to return it.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x14, to) // Store the `to` argument.
            amount := mload(0x34) // The `amount` is already at 0x34. We'll need to return it.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// If the initial attempt to approve fails, attempts to reset the approved amount to zero,
    /// then retries the approval again (some tokens, e.g. USDT, requires this).
    /// Reverts upon failure.
    function safeApproveWithRetry(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, retrying upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x34, 0) // Store 0 for the `amount`.
                mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
                pop(call(gas(), token, 0, 0x10, 0x44, codesize(), 0x00)) // Reset the approval.
                mstore(0x34, amount) // Store back the original `amount`.
                // Retry the approval, reverting upon failure.
                if iszero(
                    and(
                        or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                        call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                    )
                ) {
                    mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            amount :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error ExpOverflow();

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error FactorialOverflow();

    /// @dev The operation failed, due to an overflow.
    error RPowOverflow();

    /// @dev The operation failed, due to an multiplication overflow.
    error MulWadFailed();

    /// @dev The operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error DivWadFailed();

    /// @dev The multiply-divide operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error MulDivFailed();

    /// @dev The division failed, as the denominator is zero.
    error DivFailed();

    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @dev The output is undefined, as the input is less-than-or-equal to zero.
    error LnWadUndefined();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              SIMPLIFIED FIXED POINT OPERATIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                mstore(0x00, 0xbac65e5b) // `MulWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                mstore(0x00, 0xbac65e5b) // `MulWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down.
    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                mstore(0x00, 0x7c5f487d) // `DivWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded up.
    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                mstore(0x00, 0x7c5f487d) // `DivWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
        }
    }

    /// @dev Equivalent to `x` to the power of `y`.
    /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Using `ln(x)` means `x` must be greater than 0.
        return expWad((lnWad(x) * y) / int256(WAD));
    }

    /// @dev Returns `exp(x)`, denominated in `WAD`.
    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return r;

            /// @solidity memory-safe-assembly
            assembly {
                // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
                // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
                if iszero(slt(x, 135305999368893231589)) {
                    mstore(0x00, 0xa37bfec9) // `ExpOverflow()`.
                    revert(0x1c, 0x04)
                }
            }

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5 ** 18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256(
                (uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k)
            );
        }
    }

    /// @dev Returns `ln(x)`, denominated in `WAD`.
    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            /// @solidity memory-safe-assembly
            assembly {
                if iszero(sgt(x, 0)) {
                    mstore(0x00, 0x1615e638) // `LnWadUndefined()`.
                    revert(0x1c, 0x04)
                }
            }

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Compute k = log2(x) - 96.
            int256 k;
            /// @solidity memory-safe-assembly
            assembly {
                k := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
                k := or(k, shl(6, lt(0xffffffffffffffff, shr(k, x))))
                k := or(k, shl(5, lt(0xffffffff, shr(k, x))))
                k := or(k, shl(4, lt(0xffff, shr(k, x))))
                k := or(k, shl(3, lt(0xff, shr(k, x))))
                k := or(k, shl(2, lt(0xf, shr(k, x))))
                k := sub(or(k, byte(shr(k, x), hex"00000101020202020303030303030303")), 96)
            }

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            x = int256(uint256(x << uint256(159 - k)) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  GENERAL NUMBER UTILITIES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Calculates `floor(a * b / d)` with full precision.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Remco Bloemen under MIT license: https://2π.com/21/muldiv
    function fullMulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                // 512-bit multiply `[p1 p0] = x * y`.
                // Compute the product mod `2**256` and mod `2**256 - 1`
                // then use the Chinese Remainder Theorem to reconstruct
                // the 512 bit result. The result is stored in two 256
                // variables such that `product = p1 * 2**256 + p0`.

                // Least significant 256 bits of the product.
                let p0 := mul(x, y)
                let mm := mulmod(x, y, not(0))
                // Most significant 256 bits of the product.
                let p1 := sub(mm, add(p0, lt(mm, p0)))

                // Handle non-overflow cases, 256 by 256 division.
                if iszero(p1) {
                    if iszero(d) {
                        mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
                        revert(0x1c, 0x04)
                    }
                    result := div(p0, d)
                    break
                }

                // Make sure the result is less than `2**256`. Also prevents `d == 0`.
                if iszero(gt(d, p1)) {
                    mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
                    revert(0x1c, 0x04)
                }

                /*------------------- 512 by 256 division --------------------*/

                // Make division exact by subtracting the remainder from `[p1 p0]`.
                // Compute remainder using mulmod.
                let r := mulmod(x, y, d)
                // `t` is the least significant bit of `d`.
                // Always greater or equal to 1.
                let t := and(d, sub(0, d))
                // Divide `d` by `t`, which is a power of two.
                d := div(d, t)
                // Invert `d mod 2**256`
                // Now that `d` is an odd number, it has an inverse
                // modulo `2**256` such that `d * inv = 1 mod 2**256`.
                // Compute the inverse by starting with a seed that is correct
                // correct for four bits. That is, `d * inv = 1 mod 2**4`.
                let inv := xor(mul(3, d), 2)
                // Now use Newton-Raphson iteration to improve the precision.
                // Thanks to Hensel's lifting lemma, this also works in modular
                // arithmetic, doubling the correct bits in each step.
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
                result :=
                    mul(
                        // Divide [p1 p0] by the factors of two.
                        // Shift in bits from `p1` into `p0`. For this we need
                        // to flip `t` such that it is `2**256 / t`.
                        or(mul(sub(p1, gt(r, p0)), add(div(sub(0, t), t), 1)), div(sub(p0, r), t)),
                        // inverse mod 2**256
                        mul(inv, sub(2, mul(d, inv)))
                    )
                break
            }
        }
    }

    /// @dev Calculates `floor(x * y / d)` with full precision, rounded up.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Uniswap-v3-core under MIT license:
    /// https://github.com/Uniswap/v3-core/blob/contracts/libraries/FullMath.sol
    function fullMulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        result = fullMulDiv(x, y, d);
        /// @solidity memory-safe-assembly
        assembly {
            if mulmod(x, y, d) {
                result := add(result, 1)
                if iszero(result) {
                    mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    /// @dev Returns `floor(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                mstore(0x00, 0xad251c27) // `MulDivFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), d)
        }
    }

    /// @dev Returns `ceil(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                mstore(0x00, 0xad251c27) // `MulDivFailed()`.
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), d))), div(mul(x, y), d))
        }
    }

    /// @dev Returns `ceil(x / d)`.
    /// Reverts if `d` is zero.
    function divUp(uint256 x, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(d) {
                mstore(0x00, 0x65244e4e) // `DivFailed()`.
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(x, d))), div(x, d))
        }
    }

    /// @dev Returns `max(0, x - y)`.
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Exponentiate `x` to `y` by squaring, denominated in base `b`.
    /// Reverts if the computation overflows.
    function rpow(uint256 x, uint256 y, uint256 b) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(b, iszero(y)) // `0 ** 0 = 1`. Otherwise, `0 ** n = 0`.
            if x {
                z := xor(b, mul(xor(b, x), and(y, 1))) // `z = isEven(y) ? scale : x`
                let half := shr(1, b) // Divide `b` by 2.
                // Divide `y` by 2 every iteration.
                for { y := shr(1, y) } y { y := shr(1, y) } {
                    let xx := mul(x, x) // Store x squared.
                    let xxRound := add(xx, half) // Round to the nearest number.
                    // Revert if `xx + half` overflowed, or if `x ** 2` overflows.
                    if or(lt(xxRound, xx), shr(128, x)) {
                        mstore(0x00, 0x49f7642b) // `RPowOverflow()`.
                        revert(0x1c, 0x04)
                    }
                    x := div(xxRound, b) // Set `x` to scaled `xxRound`.
                    // If `y` is odd:
                    if and(y, 1) {
                        let zx := mul(z, x) // Compute `z * x`.
                        let zxRound := add(zx, half) // Round to the nearest number.
                        // If `z * x` overflowed or `zx + half` overflowed:
                        if or(xor(div(zx, x), z), lt(zxRound, zx)) {
                            // Revert if `x` is non-zero.
                            if iszero(iszero(x)) {
                                mstore(0x00, 0x49f7642b) // `RPowOverflow()`.
                                revert(0x1c, 0x04)
                            }
                        }
                        z := div(zxRound, b) // Return properly scaled `zxRound`.
                    }
                }
            }
        }
    }

    /// @dev Returns the square root of `x`.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`. We check `y >= 2**(k + 8)`
            // but shift right by `k` bits to ensure that if `x >= 256`, then `y >= 256`.
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffffff, shr(r, x))))
            z := shl(shr(1, r), z)

            // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `x < 256` but we can just verify those cases exhaustively.

            // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
            // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
            // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            z := sub(z, lt(div(x, z), z))
        }
    }

    /// @dev Returns the cube root of `x`.
    /// Credit to bout3fiddy and pcaversaccio under AGPLv3 license:
    /// https://github.com/pcaversaccio/snekmate/blob/main/src/utils/Math.vy
    function cbrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))

            z := div(shl(div(r, 3), shl(lt(0xf, shr(r, x)), 0xf)), xor(7, mod(r, 3)))

            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)

            z := sub(z, lt(div(x, mul(z, z)), z))
        }
    }

    /// @dev Returns the square root of `x`, denominated in `WAD`.
    function sqrtWad(uint256 x) internal pure returns (uint256 z) {
        unchecked {
            z = 10 ** 9;
            if (x <= type(uint256).max / 10 ** 36 - 1) {
                x *= 10 ** 18;
                z = 1;
            }
            z *= sqrt(x);
        }
    }

    /// @dev Returns the cube root of `x`, denominated in `WAD`.
    function cbrtWad(uint256 x) internal pure returns (uint256 z) {
        unchecked {
            z = 10 ** 12;
            if (x <= (type(uint256).max / 10 ** 36) * 10 ** 18 - 1) {
                if (x >= type(uint256).max / 10 ** 36) {
                    x *= 10 ** 18;
                    z = 10 ** 6;
                } else {
                    x *= 10 ** 36;
                    z = 1;
                }
            }
            z *= cbrt(x);
        }
    }

    /// @dev Returns the factorial of `x`.
    function factorial(uint256 x) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(x, 58)) {
                mstore(0x00, 0xaba0f2a2) // `FactorialOverflow()`.
                revert(0x1c, 0x04)
            }
            for { result := 1 } x { x := sub(x, 1) } { result := mul(result, x) }
        }
    }

    /// @dev Returns the log2 of `x`.
    /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
    /// Returns 0 if `x` is zero.
    function log2(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, byte(shr(r, x), hex"00000101020202020303030303030303"))
        }
    }

    /// @dev Returns the log2 of `x`, rounded up.
    /// Returns 0 if `x` is zero.
    function log2Up(uint256 x) internal pure returns (uint256 r) {
        r = log2(x);
        /// @solidity memory-safe-assembly
        assembly {
            r := add(r, lt(shl(r, 1), x))
        }
    }

    /// @dev Returns the log10 of `x`.
    /// Returns 0 if `x` is zero.
    function log10(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(x, 100000000000000000000000000000000000000)) {
                x := div(x, 100000000000000000000000000000000000000)
                r := 38
            }
            if iszero(lt(x, 100000000000000000000)) {
                x := div(x, 100000000000000000000)
                r := add(r, 20)
            }
            if iszero(lt(x, 10000000000)) {
                x := div(x, 10000000000)
                r := add(r, 10)
            }
            if iszero(lt(x, 100000)) {
                x := div(x, 100000)
                r := add(r, 5)
            }
            r := add(r, add(gt(x, 9), add(gt(x, 99), add(gt(x, 999), gt(x, 9999)))))
        }
    }

    /// @dev Returns the log10 of `x`, rounded up.
    /// Returns 0 if `x` is zero.
    function log10Up(uint256 x) internal pure returns (uint256 r) {
        r = log10(x);
        /// @solidity memory-safe-assembly
        assembly {
            r := add(r, lt(exp(10, r), x))
        }
    }

    /// @dev Returns the log256 of `x`.
    /// Returns 0 if `x` is zero.
    function log256(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(shr(3, r), lt(0xff, shr(r, x)))
        }
    }

    /// @dev Returns the log256 of `x`, rounded up.
    /// Returns 0 if `x` is zero.
    function log256Up(uint256 x) internal pure returns (uint256 r) {
        r = log256(x);
        /// @solidity memory-safe-assembly
        assembly {
            r := add(r, lt(shl(shl(3, r), 1), x))
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = (x & y) + ((x ^ y) >> 1);
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = (x >> 1) + (y >> 1) + (((x & 1) + (y & 1)) >> 1);
        }
    }

    /// @dev Returns the absolute value of `x`.
    function abs(int256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(sub(0, shr(255, x)), add(sub(0, shr(255, x)), x))
        }
    }

    /// @dev Returns the absolute distance between `x` and `y`.
    function dist(int256 x, int256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(mul(xor(sub(y, x), sub(x, y)), sgt(x, y)), sub(y, x))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), slt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), sgt(y, x)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(uint256 x, uint256 minValue, uint256 maxValue)
        internal
        pure
        returns (uint256 z)
    {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, minValue), gt(minValue, x)))
            z := xor(z, mul(xor(z, maxValue), lt(maxValue, z)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(int256 x, int256 minValue, int256 maxValue) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, minValue), sgt(minValue, x)))
            z := xor(z, mul(xor(z, maxValue), slt(maxValue, z)))
        }
    }

    /// @dev Returns greatest common divisor of `x` and `y`.
    function gcd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            for { z := x } y {} {
                let t := y
                y := mod(z, y)
                z := t
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   RAW NUMBER OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(x, y)
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawSDiv(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sdiv(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mod(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawSMod(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := smod(x, y)
        }
    }

    /// @dev Returns `(x + y) % d`, return 0 if `d` if zero.
    function rawAddMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := addmod(x, y, d)
        }
    }

    /// @dev Returns `(x * y) % d`, return 0 if `d` if zero.
    function rawMulMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mulmod(x, y, d)
        }
    }
}

interface IStrategy {
    function addRewardToken(address _token, address _distributor) external;

    function acceptRewardDistributorOwnership(address _rewardDistributor) external;

    function deposit(address _token, uint256 _amount) external;

    function feeReceiver() external view returns (address);

    function execute(address _to, uint256 _value, bytes memory _data)
        external
        returns (bool _success, bytes memory _result);

    function gauges(address _lp) external view returns (address);

    function locker() external view returns (address);

    function protocolFeesPercent() external view returns (uint256);

    function rewardDistributors(address _gauge) external view returns (address);

    function setGauge(address _lp, address _gauge) external;

    function setRewardDistributor(address _gauge, address _distributor) external;

    function toggleVault(address _vault) external;

    function withdraw(address _token, uint256 _amount) external;

    function setLGtype(address _gauge, uint256 _type) external;

    function setRewardReceiver(address _gauge, address _rewardReceiver) external;
}

interface ISDLiquidityGauge {
    function asset() external view returns (address);

    // solhint-disable-next-line
    function add_reward(address _token, address _distributor) external;

    function balanceOf(address _user) external view returns (uint256);

    // solhint-disable-next-line
    function commit_transfer_ownership(address _owner) external;

    // solhint-disable-next-line
    function claim_rewards(address _user) external;

    function deposit(uint256 _value, address _user) external;

    // solhint-disable-next-line
    function deposit_reward_token(address _rewardToken, uint256 _amount) external;

    function initialize(
        address _stakingToken,
        address _admin,
        address _token,
        address _veToken,
        address _veBoost,
        address _sdtDistributor,
        address _vault,
        string memory _symbol
    ) external;

    // solhint-disable-next-line
    function lp_token() external view returns (address);

    // solhint-disable-next-line
    function reward_tokens(uint256 _i) external view returns (address);

    // solhint-disable-next-line
    function set_claimer(address _claimReward) external;

    // solhint-disable-next-line
    function set_vault(address _vault) external;

    function withdraw(uint256 _value, address _user, bool _claim) external;
}

/// @title Vault Implementation for Stake DAO.
/// @notice This contract allows users to deposit LP tokens into Stake DAO and receive sdGauge tokens in return.
/// @dev Is an ERC20 Token and Clonable.
contract Vault is ERC20, Clone {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /// @notice The denominator used for percentage calculations.
    uint256 public constant DENOMINATOR = 10_000;

    /// @notice A small fee charged to incentivize the next call to the earn function.
    uint256 public constant EARN_INCENTIVE_FEE = 10;

    /// @notice The total amount of the incentive token.
    uint256 public incentiveTokenAmount;

    /// @dev Error thrown if the sender does not have enough tokens.
    error NOT_ENOUGH_TOKENS();

    /// @dev Error thrown if the contract has already been initialized.
    error ALREADY_INITIALIZED();

    //////////////////////////////////////////////////////
    /// --- IMMUTABLES
    //////////////////////////////////////////////////////

    /// @notice Returns the ERC20 LP token used by the contract.
    /// @return _token The ERC20 token used by the contract.
    function token() public pure returns (ERC20 _token) {
        return ERC20(_getArgAddress(0));
    }

    /// @notice Returns the strategy used by the contract.
    /// @return _strategy The strategy used by the contract.
    function strategy() public pure returns (IStrategy _strategy) {
        return IStrategy(_getArgAddress(20));
    }

    /// @notice Returns the liquidity gauge used by the contract.
    /// @return _liquidityGauge The liquidity gauge used by the contract.
    function liquidityGauge() public pure returns (ISDLiquidityGauge _liquidityGauge) {
        return ISDLiquidityGauge(_getArgAddress(40));
    }

    /// @notice Initializes the contract by setting allowances for the token and liquidity gauge.
    /// @dev Reverts if the contract has already been initialized.
    function initialize() external {
        if (token().allowance(address(this), address(strategy())) != 0) revert ALREADY_INITIALIZED();

        SafeTransferLib.safeApproveWithRetry(address(token()), address(strategy()), type(uint256).max);
        SafeTransferLib.safeApproveWithRetry(address(this), address(liquidityGauge()), type(uint256).max);
    }

    /// @notice Deposits a specified amount of LP tokens into the contract.
    /// @param _receiver The address for which the deposit is made.
    /// @param _amount The amount of tokens to be deposited.
    /// @param _doEarn If true, deposits LP tokens directly into the strategy.
    /// @dev If _doEarn is false, a fee is taken from the deposit to incentivize the next call to `earn`.
    /// @dev If _doEarn is true, the incentive token amount (if any) is added to the total amount, the incentive token amount is reset, and the total is deposited into the strategy.
    function deposit(address _receiver, uint256 _amount, bool _doEarn) public {
        SafeTransferLib.safeTransferFrom(address(token()), msg.sender, address(this), _amount);

        if (!_doEarn) {
            /// If doEarn is false, take a fee from the deposit to incentivize next call to earn.
            uint256 _incentiveTokenAmount = _amount.mulDiv(EARN_INCENTIVE_FEE, DENOMINATOR);

            /// Subtract incentive token amount from the total amount.
            _amount -= _incentiveTokenAmount;

            /// Add incentive token amount to the total incentive token amount.
            incentiveTokenAmount += _incentiveTokenAmount;
        } else {
            /// Add incentive token amount to the total amount.
            _amount += incentiveTokenAmount;

            /// Reset incentive token amount.
            incentiveTokenAmount = 0;

            _earn();
        }

        /// Mint amount equivalent to the amount deposited.
        _mint(address(this), _amount);

        /// Deposit for the receiver in the reward distributor gauge.
        liquidityGauge().deposit(_amount, _receiver);
    }

    /// @notice Withdraws a specified amount of LP tokens from the contract.
    /// @param _shares The amount of shares to be withdrawn.
    function withdraw(uint256 _shares) public {
        uint256 _balanceOfAccount = liquidityGauge().balanceOf(msg.sender);
        /// Revert if the sender does not have enough shares.
        if (_shares > _balanceOfAccount) revert NOT_ENOUGH_TOKENS();

        ///  Withdraw from the reward distributor gauge.
        liquidityGauge().withdraw(_shares, msg.sender, true);

        /// Burn vault shares.
        _burn(address(this), _shares);

        ///  Subtract the incentive token amount from the total amount or the next earn will dilute the shares.
        uint256 _tokenBalance = token().balanceOf(address(this)) - incentiveTokenAmount;

        /// Withdraw from the strategy if no enough tokens in the contract.
        if (_shares > _tokenBalance) {
            uint256 _toWithdraw = _shares - _tokenBalance;

            strategy().withdraw(address(token()), _toWithdraw);
        }

        /// Transfer the tokens to the sender.
        SafeTransferLib.safeTransfer(address(token()), msg.sender, _shares);
    }

    /// @notice Deposit all the LP tokens in the contract into the strategy.
    function _earn() internal {
        uint256 _balance = token().balanceOf(address(this));
        strategy().deposit(address(token()), _balance);
    }

    /// @notice Returns the name of the contract. (ERC20)
    function name() public view override returns (string memory) {
        return string(abi.encodePacked("sd", token().symbol(), " Vault"));
    }

    /// @notice Returns the symbol of the contract. (ERC20)
    function symbol() public view override returns (string memory) {
        return string(abi.encodePacked("sd", token().symbol(), "-vault"));
    }

    /// @notice Returns the decimals of the contract. (ERC20)
    function decimals() public view override returns (uint8) {
        return token().decimals();
    }
}

interface IStrategyVault {
    function initialize() external;

    function transferGovernance(address _governance) external;

    function setLiquidityGauge(address _gauge) external;
}

/// @notice Minimal proxy library.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibClone.sol)
/// @author Minimal proxy by 0age (https://github.com/0age)
/// @author Clones with immutable args by wighawag, zefram.eth, Saw-mon & Natalie
/// (https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args)
/// @author Minimal ERC1967 proxy by jtriley-eth (https://github.com/jtriley-eth/minimum-viable-proxy)
///
/// @dev Minimal proxy:
/// Although the sw0nt pattern saves 5 gas over the erc-1167 pattern during runtime,
/// it is not supported out-of-the-box on Etherscan. Hence, we choose to use the 0age pattern,
/// which saves 4 gas over the erc-1167 pattern during runtime, and has the smallest bytecode.
///
/// @dev Minimal proxy (PUSH0 variant):
/// This is a new minimal proxy that uses the PUSH0 opcode introduced during Shanghai.
/// It is optimized first for minimal runtime gas, then for minimal bytecode.
/// The PUSH0 clone functions are intentionally postfixed with a jarring "_PUSH0" as
/// many EVM chains may not support the PUSH0 opcode in the early months after Shanghai.
/// Please use with caution.
///
/// @dev Clones with immutable args (CWIA):
/// The implementation of CWIA here implements a `receive()` method that emits the
/// `ReceiveETH(uint256)` event. This skips the `DELEGATECALL` when there is no calldata,
/// enabling us to accept hard gas-capped `sends` & `transfers` for maximum backwards
/// composability. The minimal proxy implementation does not offer this feature.
///
/// @dev Minimal ERC1967 proxy:
/// An minimal ERC1967 proxy, intended to be upgraded with UUPS.
/// This is NOT the same as ERC1967Factory's transparent proxy, which includes admin logic.
library LibClone {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the clone.
    error DeploymentFailed();

    /// @dev The salt must start with either the zero address or `by`.
    error SaltDoesNotStartWith();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  MINIMAL PROXY OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a clone of `implementation`.
    function clone(address implementation) internal returns (address instance) {
        instance = clone(0, implementation);
    }

    /// @dev Deploys a clone of `implementation`.
    function clone(uint256 value, address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * --------------------------------------------------------------------------+
             * CREATION (9 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                       |
             * --------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize     | r         |                              |
             * 3d         | RETURNDATASIZE    | 0 r       |                              |
             * 81         | DUP2              | r 0 r     |                              |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                              |
             * 3d         | RETURNDATASIZE    | 0 o r 0 r |                              |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code   |
             * f3         | RETURN            |           | [0..runSize): runtime code   |
             * --------------------------------------------------------------------------|
             * RUNTIME (44 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode  | Mnemonic       | Stack                  | Memory                |
             * --------------------------------------------------------------------------|
             *                                                                           |
             * ::: keep some values in stack ::::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | 0                      |                       |
             * 3d      | RETURNDATASIZE | 0 0                    |                       |
             * 3d      | RETURNDATASIZE | 0 0 0                  |                       |
             * 3d      | RETURNDATASIZE | 0 0 0 0                |                       |
             *                                                                           |
             * ::: copy calldata to memory ::::::::::::::::::::::::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0 0 0            |                       |
             * 3d      | RETURNDATASIZE | 0 cds 0 0 0 0          |                       |
             * 3d      | RETURNDATASIZE | 0 0 cds 0 0 0 0        |                       |
             * 37      | CALLDATACOPY   | 0 0 0 0                | [0..cds): calldata    |
             *                                                                           |
             * ::: delegate call to the implementation contract :::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0 0 0            | [0..cds): calldata    |
             * 3d      | RETURNDATASIZE | 0 cds 0 0 0 0          | [0..cds): calldata    |
             * 73 addr | PUSH20 addr    | addr 0 cds 0 0 0 0     | [0..cds): calldata    |
             * 5a      | GAS            | gas addr 0 cds 0 0 0 0 | [0..cds): calldata    |
             * f4      | DELEGATECALL   | success 0 0            | [0..cds): calldata    |
             *                                                                           |
             * ::: copy return data to memory :::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | rds success 0 0        | [0..cds): calldata    |
             * 3d      | RETURNDATASIZE | rds rds success 0 0    | [0..cds): calldata    |
             * 93      | SWAP4          | 0 rds success 0 rds    | [0..cds): calldata    |
             * 80      | DUP1           | 0 0 rds success 0 rds  | [0..cds): calldata    |
             * 3e      | RETURNDATACOPY | success 0 rds          | [0..rds): returndata  |
             *                                                                           |
             * 60 0x2a | PUSH1 0x2a     | 0x2a success 0 rds     | [0..rds): returndata  |
             * 57      | JUMPI          | 0 rds                  | [0..rds): returndata  |
             *                                                                           |
             * ::: revert :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * fd      | REVERT         |                        | [0..rds): returndata  |
             *                                                                           |
             * ::: return :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b      | JUMPDEST       | 0 rds                  | [0..rds): returndata  |
             * f3      | RETURN         |                        | [0..rds): returndata  |
             * --------------------------------------------------------------------------+
             */

            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            instance := create(value, 0x0c, 0x35)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x21, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Deploys a deterministic clone of `implementation` with `salt`.
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        instance = cloneDeterministic(0, implementation, salt);
    }

    /// @dev Deploys a deterministic clone of `implementation` with `salt`.
    function cloneDeterministic(uint256 value, address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            instance := create2(value, 0x0c, 0x35, salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x21, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the initialization code hash of the clone of `implementation`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(address implementation) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            hash := keccak256(0x0c, 0x35)
            mstore(0x21, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the address of the deterministic clone of `implementation`,
    /// with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        bytes32 hash = initCodeHash(implementation);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*          MINIMAL PROXY OPERATIONS (PUSH0 VARIANT)          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a PUSH0 clone of `implementation`.
    function clone_PUSH0(address implementation) internal returns (address instance) {
        instance = clone_PUSH0(0, implementation);
    }

    /// @dev Deploys a PUSH0 clone of `implementation`.
    function clone_PUSH0(uint256 value, address implementation)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * --------------------------------------------------------------------------+
             * CREATION (9 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                       |
             * --------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize     | r         |                              |
             * 5f         | PUSH0             | 0 r       |                              |
             * 81         | DUP2              | r 0 r     |                              |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                              |
             * 5f         | PUSH0             | 0 o r 0 r |                              |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code   |
             * f3         | RETURN            |           | [0..runSize): runtime code   |
             * --------------------------------------------------------------------------|
             * RUNTIME (45 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode  | Mnemonic       | Stack                  | Memory                |
             * --------------------------------------------------------------------------|
             *                                                                           |
             * ::: keep some values in stack ::::::::::::::::::::::::::::::::::::::::::: |
             * 5f      | PUSH0          | 0                      |                       |
             * 5f      | PUSH0          | 0 0                    |                       |
             *                                                                           |
             * ::: copy calldata to memory ::::::::::::::::::::::::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0                |                       |
             * 5f      | PUSH0          | 0 cds 0 0              |                       |
             * 5f      | PUSH0          | 0 0 cds 0 0            |                       |
             * 37      | CALLDATACOPY   | 0 0                    | [0..cds): calldata    |
             *                                                                           |
             * ::: delegate call to the implementation contract :::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0                | [0..cds): calldata    |
             * 5f      | PUSH0          | 0 cds 0 0              | [0..cds): calldata    |
             * 73 addr | PUSH20 addr    | addr 0 cds 0 0         | [0..cds): calldata    |
             * 5a      | GAS            | gas addr 0 cds 0 0     | [0..cds): calldata    |
             * f4      | DELEGATECALL   | success                | [0..cds): calldata    |
             *                                                                           |
             * ::: copy return data to memory :::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | rds success            | [0..cds): calldata    |
             * 5f      | PUSH0          | 0 rds success          | [0..cds): calldata    |
             * 5f      | PUSH0          | 0 0 rds success        | [0..cds): calldata    |
             * 3e      | RETURNDATACOPY | success                | [0..rds): returndata  |
             *                                                                           |
             * 60 0x29 | PUSH1 0x29     | 0x29 success           | [0..rds): returndata  |
             * 57      | JUMPI          |                        | [0..rds): returndata  |
             *                                                                           |
             * ::: revert :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | rds                    | [0..rds): returndata  |
             * 5f      | PUSH0          | 0 rds                  | [0..rds): returndata  |
             * fd      | REVERT         |                        | [0..rds): returndata  |
             *                                                                           |
             * ::: return :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b      | JUMPDEST       |                        | [0..rds): returndata  |
             * 3d      | RETURNDATASIZE | rds                    | [0..rds): returndata  |
             * 5f      | PUSH0          | 0 rds                  | [0..rds): returndata  |
             * f3      | RETURN         |                        | [0..rds): returndata  |
             * --------------------------------------------------------------------------+
             */

            mstore(0x24, 0x5af43d5f5f3e6029573d5ffd5b3d5ff3) // 16
            mstore(0x14, implementation) // 20
            mstore(0x00, 0x602d5f8160095f39f35f5f365f5f37365f73) // 9 + 9
            instance := create(value, 0x0e, 0x36)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x24, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Deploys a deterministic PUSH0 clone of `implementation` with `salt`.
    function cloneDeterministic_PUSH0(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        instance = cloneDeterministic_PUSH0(0, implementation, salt);
    }

    /// @dev Deploys a deterministic PUSH0 clone of `implementation` with `salt`.
    function cloneDeterministic_PUSH0(uint256 value, address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x24, 0x5af43d5f5f3e6029573d5ffd5b3d5ff3) // 16
            mstore(0x14, implementation) // 20
            mstore(0x00, 0x602d5f8160095f39f35f5f365f5f37365f73) // 9 + 9
            instance := create2(value, 0x0e, 0x36, salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x24, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the initialization code hash of the PUSH0 clone of `implementation`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash_PUSH0(address implementation) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x24, 0x5af43d5f5f3e6029573d5ffd5b3d5ff3) // 16
            mstore(0x14, implementation) // 20
            mstore(0x00, 0x602d5f8160095f39f35f5f365f5f37365f73) // 9 + 9
            hash := keccak256(0x0e, 0x36)
            mstore(0x24, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the address of the deterministic PUSH0 clone of `implementation`,
    /// with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress_PUSH0(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHash_PUSH0(implementation);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*           CLONES WITH IMMUTABLE ARGS OPERATIONS            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note: This implementation of CWIA differs from the original implementation.
    // If the calldata is empty, it will emit a `ReceiveETH(uint256)` event and skip the `DELEGATECALL`.

    /// @dev Deploys a clone of `implementation` with immutable arguments encoded in `data`.
    function clone(address implementation, bytes memory data) internal returns (address instance) {
        instance = clone(0, implementation, data);
    }

    /// @dev Deploys a clone of `implementation` with immutable arguments encoded in `data`.
    function clone(uint256 value, address implementation, bytes memory data)
        internal
        returns (address instance)
    {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)
            // The `creationSize` is `extraLength + 108`
            // The `runSize` is `creationSize - 10`.

            /**
             * ---------------------------------------------------------------------------------------------------+
             * CREATION (10 bytes)                                                                                |
             * ---------------------------------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                                                |
             * ---------------------------------------------------------------------------------------------------|
             * 61 runSize | PUSH2 runSize     | r         |                                                       |
             * 3d         | RETURNDATASIZE    | 0 r       |                                                       |
             * 81         | DUP2              | r 0 r     |                                                       |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                                                       |
             * 3d         | RETURNDATASIZE    | 0 o r 0 r |                                                       |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code                            |
             * f3         | RETURN            |           | [0..runSize): runtime code                            |
             * ---------------------------------------------------------------------------------------------------|
             * RUNTIME (98 bytes + extraLength)                                                                   |
             * ---------------------------------------------------------------------------------------------------|
             * Opcode   | Mnemonic       | Stack                    | Memory                                      |
             * ---------------------------------------------------------------------------------------------------|
             *                                                                                                    |
             * ::: if no calldata, emit event & return w/o `DELEGATECALL` ::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds                      |                                             |
             * 60 0x2c  | PUSH1 0x2c     | 0x2c cds                 |                                             |
             * 57       | JUMPI          |                          |                                             |
             * 34       | CALLVALUE      | cv                       |                                             |
             * 3d       | RETURNDATASIZE | 0 cv                     |                                             |
             * 52       | MSTORE         |                          | [0..0x20): callvalue                        |
             * 7f sig   | PUSH32 0x9e..  | sig                      | [0..0x20): callvalue                        |
             * 59       | MSIZE          | 0x20 sig                 | [0..0x20): callvalue                        |
             * 3d       | RETURNDATASIZE | 0 0x20 sig               | [0..0x20): callvalue                        |
             * a1       | LOG1           |                          | [0..0x20): callvalue                        |
             * 00       | STOP           |                          | [0..0x20): callvalue                        |
             * 5b       | JUMPDEST       |                          |                                             |
             *                                                                                                    |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds                      |                                             |
             * 3d       | RETURNDATASIZE | 0 cds                    |                                             |
             * 3d       | RETURNDATASIZE | 0 0 cds                  |                                             |
             * 37       | CALLDATACOPY   |                          | [0..cds): calldata                          |
             *                                                                                                    |
             * ::: keep some values in stack :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d       | RETURNDATASIZE | 0                        | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0                      | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0 0                    | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0 0 0                  | [0..cds): calldata                          |
             * 61 extra | PUSH2 extra    | e 0 0 0 0                | [0..cds): calldata                          |
             *                                                                                                    |
             * ::: copy extra data to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 80       | DUP1           | e e 0 0 0 0              | [0..cds): calldata                          |
             * 60 0x62  | PUSH1 0x62     | 0x62 e e 0 0 0 0         | [0..cds): calldata                          |
             * 36       | CALLDATASIZE   | cds 0x62 e e 0 0 0 0     | [0..cds): calldata                          |
             * 39       | CODECOPY       | e 0 0 0 0                | [0..cds): calldata, [cds..cds+e): extraData |
             *                                                                                                    |
             * ::: delegate call to the implementation contract ::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds e 0 0 0 0            | [0..cds): calldata, [cds..cds+e): extraData |
             * 01       | ADD            | cds+e 0 0 0 0            | [0..cds): calldata, [cds..cds+e): extraData |
             * 3d       | RETURNDATASIZE | 0 cds+e 0 0 0 0          | [0..cds): calldata, [cds..cds+e): extraData |
             * 73 addr  | PUSH20 addr    | addr 0 cds+e 0 0 0 0     | [0..cds): calldata, [cds..cds+e): extraData |
             * 5a       | GAS            | gas addr 0 cds+e 0 0 0 0 | [0..cds): calldata, [cds..cds+e): extraData |
             * f4       | DELEGATECALL   | success 0 0              | [0..cds): calldata, [cds..cds+e): extraData |
             *                                                                                                    |
             * ::: copy return data to memory ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d       | RETURNDATASIZE | rds success 0 0          | [0..cds): calldata, [cds..cds+e): extraData |
             * 3d       | RETURNDATASIZE | rds rds success 0 0      | [0..cds): calldata, [cds..cds+e): extraData |
             * 93       | SWAP4          | 0 rds success 0 rds      | [0..cds): calldata, [cds..cds+e): extraData |
             * 80       | DUP1           | 0 0 rds success 0 rds    | [0..cds): calldata, [cds..cds+e): extraData |
             * 3e       | RETURNDATACOPY | success 0 rds            | [0..rds): returndata                        |
             *                                                                                                    |
             * 60 0x60  | PUSH1 0x60     | 0x60 success 0 rds       | [0..rds): returndata                        |
             * 57       | JUMPI          | 0 rds                    | [0..rds): returndata                        |
             *                                                                                                    |
             * ::: revert ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * fd       | REVERT         |                          | [0..rds): returndata                        |
             *                                                                                                    |
             * ::: return ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b       | JUMPDEST       | 0 rds                    | [0..rds): returndata                        |
             * f3       | RETURN         |                          | [0..rds): returndata                        |
             * ---------------------------------------------------------------------------------------------------+
             */

            mstore(data, 0x5af43d3d93803e606057fd5bf3) // Write the bytecode before the data.
            mstore(sub(data, 0x0d), implementation) // Write the address of the implementation.
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                // Do a out-of-gas revert if `extraLength` is too big. 0xffff - 0x62 + 0x01 = 0xff9e.
                // The actual EVM limit may be smaller and may change over time.
                sub(data, add(0x59, lt(extraLength, 0xff9e))),
                or(shl(0x78, add(extraLength, 0x62)), 0xfd6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            instance := create(value, sub(data, 0x4c), add(extraLength, 0x6c))
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Deploys a deterministic clone of `implementation`
    /// with immutable arguments encoded in `data` and `salt`.
    function cloneDeterministic(address implementation, bytes memory data, bytes32 salt)
        internal
        returns (address instance)
    {
        instance = cloneDeterministic(0, implementation, data, salt);
    }

    /// @dev Deploys a deterministic clone of `implementation`
    /// with immutable arguments encoded in `data` and `salt`.
    function cloneDeterministic(
        uint256 value,
        address implementation,
        bytes memory data,
        bytes32 salt
    ) internal returns (address instance) {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            mstore(data, 0x5af43d3d93803e606057fd5bf3) // Write the bytecode before the data.
            mstore(sub(data, 0x0d), implementation) // Write the address of the implementation.
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                // Do a out-of-gas revert if `extraLength` is too big. 0xffff - 0x62 + 0x01 = 0xff9e.
                // The actual EVM limit may be smaller and may change over time.
                sub(data, add(0x59, lt(extraLength, 0xff9e))),
                or(shl(0x78, add(extraLength, 0x62)), 0xfd6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            instance := create2(value, sub(data, 0x4c), add(extraLength, 0x6c), salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the initialization code hash of the clone of `implementation`
    /// using immutable arguments encoded in `data`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(address implementation, bytes memory data)
        internal
        pure
        returns (bytes32 hash)
    {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // Do a out-of-gas revert if `dataLength` is too big. 0xffff - 0x02 - 0x62 = 0xff9b.
            // The actual EVM limit may be smaller and may change over time.
            returndatacopy(returndatasize(), returndatasize(), gt(dataLength, 0xff9b))

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            mstore(data, 0x5af43d3d93803e606057fd5bf3) // Write the bytecode before the data.
            mstore(sub(data, 0x0d), implementation) // Write the address of the implementation.
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(shl(0x78, add(extraLength, 0x62)), 0x6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            hash := keccak256(sub(data, 0x4c), add(extraLength, 0x6c))

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the address of the deterministic clone of
    /// `implementation` using immutable arguments encoded in `data`, with `salt`, by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress(
        address implementation,
        bytes memory data,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHash(implementation, data);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              MINIMAL ERC1967 PROXY OPERATIONS              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note: The ERC1967 proxy here is intended to be upgraded with UUPS.
    // This is NOT the same as ERC1967Factory's transparent proxy, which includes admin logic.

    /// @dev Deploys a minimal ERC1967 proxy with `implementation`.
    function deployERC1967(address implementation) internal returns (address instance) {
        instance = deployERC1967(0, implementation);
    }

    /// @dev Deploys a minimal ERC1967 proxy with `implementation`.
    function deployERC1967(uint256 value, address implementation)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * ---------------------------------------------------------------------------------+
             * CREATION (34 bytes)                                                              |
             * ---------------------------------------------------------------------------------|
             * Opcode     | Mnemonic       | Stack            | Memory                          |
             * ---------------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize  | r                |                                 |
             * 3d         | RETURNDATASIZE | 0 r              |                                 |
             * 81         | DUP2           | r 0 r            |                                 |
             * 60 offset  | PUSH1 offset   | o r 0 r          |                                 |
             * 3d         | RETURNDATASIZE | 0 o r 0 r        |                                 |
             * 39         | CODECOPY       | 0 r              | [0..runSize): runtime code      |
             * 73 impl    | PUSH20 impl    | impl 0 r         | [0..runSize): runtime code      |
             * 60 slotPos | PUSH1 slotPos  | slotPos impl 0 r | [0..runSize): runtime code      |
             * 51         | MLOAD          | slot impl 0 r    | [0..runSize): runtime code      |
             * 55         | SSTORE         | 0 r              | [0..runSize): runtime code      |
             * f3         | RETURN         |                  | [0..runSize): runtime code      |
             * ---------------------------------------------------------------------------------|
             * RUNTIME (62 bytes)                                                               |
             * ---------------------------------------------------------------------------------|
             * Opcode     | Mnemonic       | Stack            | Memory                          |
             * ---------------------------------------------------------------------------------|
             *                                                                                  |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36         | CALLDATASIZE   | cds              |                                 |
             * 3d         | RETURNDATASIZE | 0 cds            |                                 |
             * 3d         | RETURNDATASIZE | 0 0 cds          |                                 |
             * 37         | CALLDATACOPY   |                  | [0..calldatasize): calldata     |
             *                                                                                  |
             * ::: delegatecall to implementation ::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | 0                |                                 |
             * 3d         | RETURNDATASIZE | 0 0              |                                 |
             * 36         | CALLDATASIZE   | cds 0 0          | [0..calldatasize): calldata     |
             * 3d         | RETURNDATASIZE | 0 cds 0 0        | [0..calldatasize): calldata     |
             * 7f slot    | PUSH32 slot    | s 0 cds 0 0      | [0..calldatasize): calldata     |
             * 54         | SLOAD          | i 0 cds 0 0      | [0..calldatasize): calldata     |
             * 5a         | GAS            | g i 0 cds 0 0    | [0..calldatasize): calldata     |
             * f4         | DELEGATECALL   | succ             | [0..calldatasize): calldata     |
             *                                                                                  |
             * ::: copy returndata to memory :::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | rds succ         | [0..calldatasize): calldata     |
             * 60 0x00    | PUSH1 0x00     | 0 rds succ       | [0..calldatasize): calldata     |
             * 80         | DUP1           | 0 0 rds succ     | [0..calldatasize): calldata     |
             * 3e         | RETURNDATACOPY | succ             | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: branch on delegatecall status :::::::::::::::::::::::::::::::::::::::::::::: |
             * 60 0x38    | PUSH1 0x38     | dest succ        | [0..returndatasize): returndata |
             * 57         | JUMPI          |                  | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: delegatecall failed, revert :::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | rds              | [0..returndatasize): returndata |
             * 60 0x00    | PUSH1 0x00     | 0 rds            | [0..returndatasize): returndata |
             * fd         | REVERT         |                  | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: delegatecall succeeded, return ::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b         | JUMPDEST       |                  | [0..returndatasize): returndata |
             * 3d         | RETURNDATASIZE | rds              | [0..returndatasize): returndata |
             * 60 0x00    | PUSH1 0x00     | 0 rds            | [0..returndatasize): returndata |
             * f3         | RETURN         |                  | [0..returndatasize): returndata |
             * ---------------------------------------------------------------------------------+
             */

            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(0x40, 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x20, 0x6009)
            mstore(0x1e, implementation)
            mstore(0x0a, 0x603d3d8160223d3973)
            instance := create(value, 0x21, 0x5f)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Deploys a deterministic minimal ERC1967 proxy with `implementation` and `salt`.
    function deployDeterministicERC1967(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        instance = deployDeterministicERC1967(0, implementation, salt);
    }

    /// @dev Deploys a deterministic minimal ERC1967 proxy with `implementation` and `salt`.
    function deployDeterministicERC1967(uint256 value, address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(0x40, 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x20, 0x6009)
            mstore(0x1e, implementation)
            mstore(0x0a, 0x603d3d8160223d3973)
            instance := create2(value, 0x21, 0x5f, salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Returns the initialization code hash of the clone of `implementation`
    /// using immutable arguments encoded in `data`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHashERC1967(address implementation) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(0x40, 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x20, 0x6009)
            mstore(0x1e, implementation)
            mstore(0x0a, 0x603d3d8160223d3973)
            hash := keccak256(0x21, 0x5f)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Returns the address of the deterministic clone of
    /// `implementation` using immutable arguments encoded in `data`, with `salt`, by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddressERC1967(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHashERC1967(implementation);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      OTHER OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the address when a contract with initialization code hash,
    /// `hash`, is deployed with `salt`, by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress(bytes32 hash, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            mstore(0x35, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Requires that `salt` starts with either the zero address or `by`.
    function checkStartsWith(bytes32 salt, address by) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            // If the salt does not start with the zero address or `by`.
            if iszero(or(iszero(shr(96, salt)), eq(shr(96, shl(96, by)), shr(96, salt)))) {
                mstore(0x00, 0x0c4549ef) // `SaltDoesNotStartWith()`.
                revert(0x1c, 0x04)
            }
        }
    }
}

interface ILiquidityGauge {
    struct Reward {
        address token;
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }

    function deposit_reward_token(address _rewardToken, uint256 _amount) external;

    function claim_rewards_for(address _user, address _recipient) external;

    function working_balances(address _address) external view returns (uint256);

    function deposit(uint256 _value, address _addr) external;

    function reward_tokens(uint256 _i) external view returns (address);

    function reward_data(address _tokenReward) external view returns (Reward memory);

    function balanceOf(address) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function claimable_reward(address _user, address _reward_token) external view returns (uint256);

    function claimable_tokens(address _user) external returns (uint256);

    function user_checkpoint(address _user) external returns (bool);

    function commit_transfer_ownership(address) external;

    function apply_transfer_ownership() external;

    function claim_rewards(address) external;

    function add_reward(address, address) external;

    function set_claimer(address) external;

    function admin() external view returns (address);

    function lp_token() external view returns (address);

    function set_reward_distributor(address _rewardToken, address _newDistrib) external;

    function initialize(
        address staking_token,
        address admin,
        address SDT,
        address voting_escrow,
        address veBoost_proxy,
        address distributor
    ) external;
}

/// @notice Factory built to be compatible with CRV gauges but can be overidden to support other gauges/protocols.
abstract contract PoolFactory {
    using LibClone for address;

    /// @notice Denominator for fixed point math.
    uint256 public constant DENOMINATOR = 10_000;

    /// @notice Stake DAO strategy contract address.
    IStrategy public immutable strategy;

    /// @notice Reward token address.
    address public immutable rewardToken;

    /// @notice Staking Deposit implementation address.
    address public immutable vaultImplementation;

    /// @notice Liquidity Gauge implementation address.
    address public immutable liquidityGaugeImplementation;

    /// @notice Stake DAO token address.
    address public constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;

    /// @notice Voting Escrow Stake DAO token address.
    address public constant VESDT = 0x0C30476f66034E11782938DF8e4384970B6c9e8a;

    /// @notice SDT VEBoost proxy address.
    address public constant VE_BOOST_PROXY = 0xD67bdBefF01Fc492f1864E61756E5FBB3f173506;

    /// @notice Claim helper contract address for LiquidityGauges.
    address public constant CLAIM_HELPER = 0x633120100e108F03aCe79d6C78Aac9a56db1be0F;

    /// @notice Stake DAO token distributor address.
    address public constant SDT_DISTRIBUTOR = 0x9C99dffC1De1AfF7E7C1F36fCdD49063A281e18C;

    /// @notice Throwed if the gauge is not valid candidate.
    error INVALID_GAUGE();

    /// @notice Throwed if the token is not valid.
    error INVALID_TOKEN();

    /// @notice Throwed if the gauge has been already used.
    error GAUGE_ALREADY_USED();

    /// @notice Emitted when a new pool is deployed.
    event PoolDeployed(address vault, address rewardDistributor, address token, address gauge);

    /// @notice Constructor.
    /// @param _strategy Address of the strategy contract. This contract should have the ability to add new reward tokens.
    /// @param _rewardToken Address of the main reward token.
    /// @param _vaultImplementation Address of the staking deposit implementation. Main entry point.
    /// @param _liquidityGaugeImplementation Address of the liquidity gauge implementation.
    constructor(
        address _strategy,
        address _rewardToken,
        address _vaultImplementation,
        address _liquidityGaugeImplementation
    ) {
        rewardToken = _rewardToken;
        strategy = IStrategy(_strategy);
        vaultImplementation = _vaultImplementation;
        liquidityGaugeImplementation = _liquidityGaugeImplementation;
    }

    /// @notice Add new staking gauge to Stake DAO Locker.
    /// @param _gauge Address of the liquidity gauge.
    /// @return vault Address of the staking deposit.
    /// @return rewardDistributor Address of the reward distributor to claim rewards.
    function create(address _gauge) public virtual returns (address vault, address rewardDistributor) {
        /// Perform checks on the gauge to make sure it's valid and can be used.
        if (!_isValidGauge(_gauge)) revert INVALID_GAUGE();

        /// Perform checks on the strategy to make sure it's not already used.
        if (strategy.rewardDistributors(_gauge) != address(0)) revert GAUGE_ALREADY_USED();

        /// Retrieve the staking token.
        address lp = _getGaugeStakingToken(_gauge);

        /// Clone the Reward Distributor.
        rewardDistributor = LibClone.clone(liquidityGaugeImplementation);

        /// We use the LP token and the gauge address as salt to generate the vault address.
        bytes32 salt = keccak256(abi.encodePacked(lp, _gauge));

        /// We use CWIA setup. We encode the LP token, the strategy address and the reward distributor address as data
        /// to be passed as immutable args to the vault.
        bytes memory vaultData = abi.encodePacked(lp, address(strategy), rewardDistributor);

        /// Clone the Vault.
        vault = vaultImplementation.cloneDeterministic(vaultData, salt);

        /// Retrieve the symbol to be used on the reward distributor.
        (, string memory _symbol) = _getNameAndSymbol(lp);

        /// Initialize the Reward Distributor.
        ISDLiquidityGauge(rewardDistributor).initialize(
            vault, address(this), SDT, VESDT, VE_BOOST_PROXY, SDT_DISTRIBUTOR, vault, _symbol
        );

        /// Initialize Vault.
        IStrategyVault(vault).initialize();

        /// Allow the vault to stake the LP token in the locker trough the strategy.
        strategy.toggleVault(vault);

        /// Map in the strategy the staking token to it's corresponding gauge.
        strategy.setGauge(lp, _gauge);

        /// Map the gauge to the reward distributor that should receive the rewards.
        strategy.setRewardDistributor(_gauge, rewardDistributor);

        /// Add the reward token to the reward distributor.
        _addRewardToken(rewardDistributor);

        /// Set ClaimHelper as claimer.
        ISDLiquidityGauge(rewardDistributor).set_claimer(CLAIM_HELPER);

        /// Transfer ownership of the reward distributor to the strategy.
        ISDLiquidityGauge(rewardDistributor).commit_transfer_ownership(address(strategy));

        /// Accept ownership of the reward distributor.
        strategy.acceptRewardDistributorOwnership(rewardDistributor);

        /// Add extra rewards if any.
        _addExtraRewards(_gauge);

        emit PoolDeployed(vault, rewardDistributor, lp, _gauge);
    }

    /// @notice Add the main reward token to the reward distributor.
    /// @param rewardDistributor Address of the reward distributor.
    function _addRewardToken(address rewardDistributor) internal virtual {
        /// The strategy should claim through the locker the reward token,
        /// and distribute it to the reward distributor every harvest.
        ISDLiquidityGauge(rewardDistributor).add_reward(rewardToken, address(strategy));
    }

    /// @notice Add extra reward tokens to the reward distributor.
    /// @param _gauge Address of the liquidity gauge.
    function _addExtraRewards(address _gauge) internal virtual {
        /// Check if the gauge supports extra rewards.
        /// This function is not supported on all gauges, depending on when they were deployed.
        bytes memory data = abi.encodeWithSignature("reward_tokens(uint256)", 0);

        /// Hence the call to the function is wrapped in a try catch.
        (bool success,) = _gauge.call(data);
        if (!success) {
            /// If it fails, we set the LGtype to 1 to indicate that the gauge doesn't support extra rewards.
            /// So the harvest would skip the extra rewards.
            strategy.setLGtype(_gauge, 1);

            return;
        }

        /// Loop through the extra reward tokens.
        /// 8 is the maximum number of extra reward tokens supported by the gauges.
        for (uint8 i = 0; i < 8;) {
            /// Get the extra reward token address.
            address _extraRewardToken = ISDLiquidityGauge(_gauge).reward_tokens(i);

            /// If the address is 0, it means there are no more extra reward tokens.
            if (_extraRewardToken == address(0)) break;

            /// Performs checks on the extra reward token.
            /// Checks like if the token is also an lp token that can be staked in the locker, these tokens are not supported.
            if (_isValidToken(_extraRewardToken)) {
                /// Then we add the extra reward token to the reward distributor through the strategy.
                strategy.addRewardToken(_gauge, _extraRewardToken);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Perform checks on the gauge to make sure it's valid and can be used.
    /// @param _gauge Address of the liquidity gauge.
    function _isValidGauge(address _gauge) internal view virtual returns (bool) {}

    /// @notice Perform checks on the token to make sure it's valid and can be used.
    /// @param _token Address of the token.
    function _isValidToken(address _token) internal view virtual returns (bool) {}

    /// @notice Retrieve the staking token from the gauge.
    /// @param _gauge Address of the liquidity gauge.
    function _getGaugeStakingToken(address _gauge) internal view virtual returns (address lp) {
        lp = ILiquidityGauge(_gauge).lp_token();
    }

    /// @notice Retrieve the name and symbol of the staking token.
    /// @param _lp Address of the staking token.
    function _getNameAndSymbol(address _lp) internal view virtual returns (string memory name, string memory symbol) {
        name = ERC20(_lp).name();
        symbol = ERC20(_lp).symbol();
    }
}

interface IYearnGauge {
    function getReward(address _account) external;

    function setRecipient(address _recipient) external;
}

interface IGaugeController {
    // solhint-disable-next-line
    function get_gauge_weight(address _gauge) external view returns (uint256);
}

/// @title RewardReceiverSingleToken.
/// @dev Contract used only to receive the _rewardToken and approve the _strategy to transfer it.
contract RewardReceiverSingleToken {
    constructor(address _rewardToken, address _strategy) {
        SafeTransferLib.safeApprove(_rewardToken, _strategy, type(uint256).max);
    }
}

interface ILiquidityGaugeStrat {
    function asset() external view returns (address);

    function earned(address) external view returns (uint256);

    function getReward(address) external;

    // solhint-disable-next-line
    function add_reward(address _token, address _distributor) external;

    function balanceOf(address _user) external view returns (uint256);

    // solhint-disable-next-line
    function commit_transfer_ownership(address _owner) external;

    // solhint-disable-next-line
    function claim_rewards(address _user) external;

    function deposit(uint256 _value, address _user) external;

    // solhint-disable-next-line
    function deposit_reward_token(address _rewardToken, uint256 _amount) external;

    function initialize(
        address _stakingToken,
        address _admin,
        address _token,
        address _veToken,
        address _veBoost,
        address _sdtDistributor,
        address _vault,
        string memory _symbol
    ) external;

    // solhint-disable-next-line
    function lp_token() external view returns (address);

    // solhint-disable-next-line
    function reward_tokens(uint256 _i) external view returns (address);

    // solhint-disable-next-line
    function set_claimer(address _claimReward) external;

    // solhint-disable-next-line
    function set_vault(address _vault) external;

    function withdraw(uint256 _value, address _user, bool _claim) external;
}

/// @title Factory contract used to create new yearn LP vaults.
contract YearnVaultFactoryOwnable is PoolFactory {
    /// @notice Governance address
    address public governance;

    /// @notice Future governance address
    address public futureGovernance;

    /// @notice Emitted when a reward received is deployed
    event RewardReceiverDeployed(address _deployed, address _sdGauge);

    /// @notice Emitted when a governance change
    event GovernanceChanged(address _governance);

    /// @notice Throwed if the call failed
    error CALL_FAILED();

    /// @notice Throwed if caller is not allowed
    error NOT_ALLOWED();

    /// @notice Constructor.
    /// @param _strategy Address of the strategy contract. This contract should have the ability to add new reward tokens.
    /// @param _vaultImpl Address of the staking deposit implementation. Main entry point.
    /// @param _gaugeImpl Address of the liquidity gauge implementation.
    constructor(address _strategy, address _vaultImpl, address _gaugeImpl)
        PoolFactory(_strategy, address(0x41252E8691e964f7DE35156B68493bAb6797a275), _vaultImpl, _gaugeImpl)
    {
        governance = msg.sender;
    }

    /// @notice Add new staking gauge to Stake DAO Locker.
    /// @param _gauge Address of the liquidity gauge.
    /// @return _vault Address of the staking deposit.
    /// @return _rewardDistributor Address of the reward distributor to claim rewards.
    function create(address _gauge) public override returns (address _vault, address _rewardDistributor) {
        if (msg.sender != governance) revert NOT_ALLOWED();
        /// Deploy Vault + Gauge.
        (_vault, _rewardDistributor) = super.create(_gauge);
        /// Deploy RewardReceiver.
        RewardReceiverSingleToken rewardReceiver = new RewardReceiverSingleToken(rewardToken, address(strategy));

        /// Set reward receiver in strategy.
        strategy.setRewardReceiver(_gauge, address(rewardReceiver));

        emit RewardReceiverDeployed(address(rewardReceiver), _rewardDistributor);
    }

    /// @notice Transfer the governance to a new address.
    /// @param _governance Address of the new governance.
    function transferGovernance(address _governance) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        futureGovernance = _governance;
    }

    /// @notice Accept the governance transfer.
    function acceptGovernance() external {
        if (msg.sender != futureGovernance) revert NOT_ALLOWED();

        governance = msg.sender;
        emit GovernanceChanged(msg.sender);
    }

    /// @notice Add extra reward tokens to the reward distributor.
    function _addExtraRewards(address) internal override {}

    /// @notice Retrieve the staking token from the gauge.
    /// @param _gauge Address of the liquidity gauge.
    function _getGaugeStakingToken(address _gauge) internal view override returns (address lp) {
        lp = ILiquidityGaugeStrat(_gauge).asset();
    }

    /// @notice Perform checks on the gauge to make sure it's valid and can be used.
    function _isValidGauge(address) internal pure override returns (bool) {
        return true;
    }
}