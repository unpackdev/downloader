// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";

contract WhirlDeposit is Ownable {
    error PausedContract();
    error ZeroAddress();
    error UnsupportedToken();
    error TransferFailed();

    bytes32 private constant DEPOSIT_EVT_SIG
        = 0x5548c837ab068cf56a2c2479df0882a4922fd203edb7517321831d95078c5f62;
    address private constant NATIVE
        = 0x0000000000000000000000000000000000000000;

    address public relayer;
    bool public paused;

    mapping(address => bool) supportedTokens;

    event RelayerUpdated(address);
    event PausedUpdated(bool);
    event SupportedTokensUpdated(address, bool);
    event Deposit(address indexed user, address indexed token, uint256 amount);

    constructor(address relayer_) {
        _initializeOwner(msg.sender);

        relayer = relayer_;
    }

    // OWNER

    function updateRelayer(address relayer_) external {
        _checkOwner();

        if (relayer_ == NATIVE)
            _revert(ZeroAddress.selector);

        relayer = relayer_;

        emit RelayerUpdated(relayer_);
    }

    function updateSupportedTokens(address token_, bool enabled_) external {
        _checkOwner();

        if (token_ == NATIVE)
            _revert(ZeroAddress.selector);

        supportedTokens[token_] = enabled_;

        emit SupportedTokensUpdated(token_, enabled_);
    }

    function updatePaused(bool paused_) external {
        _checkOwner();

        paused = paused_;

        emit PausedUpdated(paused_);
    }

    function withdraw(uint256 amount_) external {
        _checkOwner();

        _safeTransferETH(owner(), amount_);
    }

    function withdrawToken(address token_, uint256 amount_) external {
        _checkOwner();

        _safeTransfer(token_, owner(), amount_);
    }

    // PUB/EXTERNAL

    function deposit() external payable {
        if (paused) _revert(PausedContract.selector);

        _safeTransferETH(relayer, msg.value);

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, callvalue())
            log3(0x00, 0x20, DEPOSIT_EVT_SIG, caller(), 0x0)
        }
    }

    function depositToken(address token_, uint256 amount_) external payable {
        if (paused) _revert(PausedContract.selector);
        if (!supportedTokens[token_]) _revert(UnsupportedToken.selector);

        _safeTransferFrom(
            token_,
            msg.sender,
            relayer,
            amount_
        );

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, amount_)
            log3(0x00, 0x20, DEPOSIT_EVT_SIG, caller(), token_)
        }
    }

    // PRV/INTERNAL

    function _safeTransferETH(address to_, uint256 amount_) private {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gas(), to_, amount_, 0, 0, 0, 0)) {
                mstore(0x0, 0x90b8ec18)
                revert(0x0, 0x4)
            }
        }
    }

    function _safeTransfer(
        address token_,
        address to_,
        uint256 amount_
    ) private {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to_) // Store the `to` argument.
            mstore(0x34, amount_) // Store the `amount` argument.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token_, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    function _safeTransferFrom(
        address token_,
        address from_,
        address to_,
        uint256 amount_
    ) private {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, amount_) // Store the `amount` argument.
            mstore(0x40, to_) // Store the `to` argument.
            mstore(0x2c, shl(96, from_)) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token_, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    function _revert(bytes4 code) private pure {
        assembly {
            mstore(0x0, code)
            revert(0x0, 0x4)
        }
    }
}
