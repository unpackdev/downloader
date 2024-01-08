// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

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
// Visit <https://www.gnu.org/licenses/>for a copy of the GNU Affero General Public License

///@author Zapper
///@notice this contract pipes (rebalances) liquidity among arbitrary pools/vaults

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;
import "./ZapOutBaseV1.sol";

contract Zapper_Liquidity_Pipe_V1 is ZapOutBaseV1 {
    // calldata only accepted for approved zap contracts
    mapping(address => bool) public approvedTargets;

    modifier OnlyAuthorized(address[] memory swapTargets) {
        require(
            (approvedTargets[swapTargets[0]] || swapTargets[0] == address(0)) &&
                ((approvedTargets[swapTargets[1]]) ||
                    swapTargets[1] == address(0)),
            "Target not Authorized"
        );
        _;
    }

    event zapPipe(
        address sender,
        address fromPool,
        address toPool,
        uint256 tokensRec
    );

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    /**
    @param fromPool Pool/vault token address from which to remove liquidity
    @param IncomingLP Quantity of LP to remove from fromPool
    @param intermediateToken Token to exit fromPool into
    @param toPool Destination pool/vault token address
    @param minPoolTokens Minimum quantity of tokens to receive
    @param swapTargets Execution targets for Zaps
    @param swapData Zap data
    @param affiliate Affiliate address
    */
    function ZapPipe(
        address fromPool,
        uint256 IncomingLP,
        address intermediateToken,
        address toPool,
        uint256 minPoolTokens,
        address[] calldata swapTargets,
        bytes[] calldata swapData,
        address affiliate
    )
        external
        stopInEmergency
        OnlyAuthorized(swapTargets)
        returns (uint256 tokensRec)
    {
        IERC20(fromPool).safeTransferFrom(
            msg.sender,
            address(this),
            IncomingLP
        );

        uint256 intermediateAmt =
            _fillQuote(
                fromPool,
                intermediateToken,
                IncomingLP,
                swapTargets[0],
                swapData[0]
            );

        uint256 goodwill =
            _subtractGoodwill(
                intermediateToken,
                intermediateAmt,
                affiliate,
                true
            );

        tokensRec = _fillQuote(
            intermediateToken,
            toPool,
            intermediateAmt.sub(goodwill),
            swapTargets[1],
            swapData[1]
        );

        require(tokensRec >= minPoolTokens, "ERR: High Slippage");

        emit zapPipe(msg.sender, fromPool, toPool, tokensRec);

        IERC20(toPool).safeTransfer(msg.sender, tokensRec.sub(goodwill));
    }

    function _fillQuote(
        address fromToken,
        address toToken,
        uint256 amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 finalBalance) {
        uint256 valueToSend;
        if (fromToken == address(0)) valueToSend = amount;
        else _approveToken(fromToken, swapTarget);

        uint256 initialBalance = _getBalance(toToken);

        (bool success, ) = swapTarget.call.value(valueToSend)(swapData);
        require(success, "Error Swapping Tokens");

        finalBalance = _getBalance(toToken).sub(initialBalance);

        require(finalBalance > 0, "Swapped to Invalid Token");
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }
}
