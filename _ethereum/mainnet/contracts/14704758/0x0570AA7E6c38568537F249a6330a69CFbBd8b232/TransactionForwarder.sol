// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2022 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

/// @author Zapper
/// @notice Transaction Forwarder contract

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract TransactionForwarder is Ownable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    bool public stopped;
    address public signer;

    uint256 constant BPS_MAX = 10_000;

    event Deposit(
        address indexed user,
        address indexed fromToken,
        address indexed poolToken,
        uint256 amountIn
    );

    event Withdraw(
        address indexed user,
        address indexed poolToken,
        address indexed toToken,
        uint256 amountOut
    );

    modifier stopInEmergency() {
        require(!stopped, "Paused");
        _;
    }

    // --- External Mutable Functions ---

    /**
        @notice Function to deposit underlying token to a protocol, and return `poolToken` back to user
        @dev `txData` should have the ERC20 amount encoded after deducting `bpsFee`, ETH fee is handled in the contract
        @param fromToken Token used for entry (address(0) if ether)
        @param amountIn Amount of `fromToken` to deposit
        @param poolToken Address of pool or vault to deposit into
        @param minPoolTokens Minimum acceptable quantity of `poolTokens` to receive. Reverts otherwise
        @param txTarget Execution target for the deposit
        @param txData Calldata for `txTarget`
        @param bpsFee Fees being deducted in bps
        @param signature Signed message hash by `signer`
    */
    function deposit(
        address fromToken,
        uint256 amountIn,
        address poolToken,
        uint256 minPoolTokens,
        address txTarget,
        bytes calldata txData,
        uint256 bpsFee,
        bytes calldata signature
    ) external payable stopInEmergency {
        {
            bytes32 messageHash = keccak256(
                abi.encodePacked(txTarget, txData, bpsFee)
            );
            require(_verify(messageHash, signature), "invalid signature");
        }

        uint256 ethToSend = _pullTokens(
            fromToken,
            amountIn,
            poolToken,
            txTarget,
            bpsFee
        );

        uint256 initialBalance = _getBalance(poolToken);
        (bool success, ) = txTarget.call{ value: ethToSend }(txData);
        require(success, "Error depositing");
        uint256 poolTokensRec = _getBalance(poolToken) - initialBalance;
        require(poolTokensRec >= minPoolTokens, "High Slippage");

        IERC20(poolToken).safeTransfer(msg.sender, poolTokensRec);
    }

    /**
        @notice Function to withdraw underlying token from a protocol, and return `toToken` back to user
        @param poolToken Address of pool or vault to withdraw from
        @param amountIn Amount of `poolToken` to withdraw
        @param toToken Underlying token to exit from protocol
        @param minToTokens Minimum acceptable quantity of `toToken` to receive. Reverts otherwise
        @param txTarget Execution target for the wtihdraw
        @param txData Calldata for `txTarget`
        @param bpsFee Fees being deducted in bps
        @param signature Signed message hash by `signer`
    */
    function withdraw(
        address poolToken,
        uint256 amountIn,
        address toToken,
        uint256 minToTokens,
        address txTarget,
        bytes calldata txData,
        uint256 bpsFee,
        bytes calldata signature
    ) external payable stopInEmergency {
        bytes32 messageHash = keccak256(
            abi.encodePacked(txTarget, txData, bpsFee)
        );
        require(_verify(messageHash, signature), "invalid signature");

        IERC20(poolToken).safeTransferFrom(msg.sender, address(this), amountIn);

        uint256 initialBalance = _getBalance(toToken);
        (bool success, ) = txTarget.call(txData);
        require(success, "Error withdrawing");
        uint256 toTokensRec = _getBalance(toToken) - initialBalance;

        require(toTokensRec >= minToTokens, "High Slippage");

        uint256 toSend = _getAmtAfterFees(toTokensRec, bpsFee);
        if (toToken == address(0)) {
            _sendETH(msg.sender, toSend);
        } else {
            IERC20(toToken).safeTransfer(msg.sender, toSend);
        }

        emit Withdraw(msg.sender, poolToken, toToken, toTokensRec);
    }

    // --- External onlyOwner Functions ---

    ///@notice Withdraw fees collected
    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == address(0)) {
                qty = address(this).balance;

                _sendETH(msg.sender, qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).safeTransfer(msg.sender, qty);
            }
        }
    }

    ///@notice Toggles the contract's active state
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    ///@notice Change signer address
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    // --- Internal View Functions ---

    function _verify(bytes32 messageHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return
            messageHash.toEthSignedMessageHash().recover(signature) == signer;
    }

    function _getAmtAfterFees(uint256 amount, uint256 bpsFee)
        internal
        pure
        returns (uint256)
    {
        uint256 fee = (amount * bpsFee) / BPS_MAX;
        return amount - fee;
    }

    function _getBalance(address token)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    // --- Internal Mutable Functions ---

    function _pullTokens(
        address fromToken,
        uint256 amountIn,
        address poolToken,
        address txTarget,
        uint256 bpsFee
    ) internal returns (uint256 ethToSend) {
        if (fromToken == address(0)) {
            require(msg.value > 0, "No ETH sent");

            ethToSend = _getAmtAfterFees(msg.value, bpsFee);
            emit Deposit(msg.sender, address(0), poolToken, msg.value);
        } else {
            require(msg.value == 0, "ETH sent with token");

            IERC20(fromToken).safeTransferFrom(
                msg.sender,
                address(this),
                amountIn
            );
            emit Deposit(msg.sender, fromToken, poolToken, amountIn);

            _approveToken(fromToken, txTarget);
        }
    }

    function _approveToken(address token, address spender) internal {
        if (IERC20(token).allowance(address(this), spender) > 0) return;
        else {
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }

    function _sendETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{ value: amount }("");
        require(success, "Unable to send ETH");
    }

    receive() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}
