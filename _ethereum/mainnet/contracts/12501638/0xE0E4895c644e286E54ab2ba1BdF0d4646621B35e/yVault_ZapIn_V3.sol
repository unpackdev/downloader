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

///@author Zapper
///@notice This contract adds liquidity to Yearn Vaults using ETH or ERC20 Tokens.
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "./ZapInBaseV1.sol";

interface IYVault {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function getPricePerFullShare() external view returns (uint256);

    function token() external view returns (address);

    // V2
    function pricePerShare() external view returns (uint256);
}

// -- Aave --
interface IAaveLendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);

    function getLendingPoolCore() external view returns (address payable);
}

interface IAaveLendingPoolCore {
    function getReserveATokenAddress(address _reserve)
        external
        view
        returns (address);
}

interface IAaveLendingPool {
    function deposit(
        address _reserve,
        uint256 _amount,
        uint16 _referralCode
    ) external payable;
}

contract yVault_ZapIn_V3 is ZapInBaseV1 {
    // calldata only accepted for approved zap contracts
    mapping(address => bool) public approvedTargets;

    IAaveLendingPoolAddressesProvider
        private constant lendingPoolAddressProvider =
        IAaveLendingPoolAddressesProvider(
            0x24a42fD28C976A61Df5D00D0599C34c4f90748c8
        );

    event zapIn(address sender, address pool, uint256 tokensRec);

    constructor(
        address _curveZapIn,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) public ZapBaseV1(_goodwill, _affiliateSplit) {}

    /**
    @notice This function adds liquidity to a Yearn vaults with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param toVault Yearn vault address
    @param superVault Super vault to depoist toVault tokens into (address(0) if none)
    @param isAaveUnderlying True if vault contains aave token
    @param minYVTokens The minimum acceptable quantity vault tokens to receive. Reverts otherwise
    @param intermediateToken Token to swap fromToken to before entering vault
    @param swapTarget Excecution target for the swap or Zap
    @param swapData DEX quote or Zap data
    @param affiliate Affiliate address
    @return tokensReceived- Quantity of Vault tokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address toVault,
        address superVault,
        bool isAaveUnderlying,
        uint256 minYVTokens,
        address intermediateToken,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 tokensReceived) {
        require(
            approvedTargets[swapTarget] || swapTarget == address(0),
            "Target not Authorized"
        );

        // get incoming tokens
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        // get intermediate token
        uint256 intermediateAmt =
            _fillQuote(
                fromToken,
                intermediateToken,
                toInvest,
                swapTarget,
                swapData
            );

        // get 'aIntermediateToken'
        if (isAaveUnderlying) {
            address aaveLendingPoolCore =
                lendingPoolAddressProvider.getLendingPoolCore();
            _approveToken(intermediateToken, aaveLendingPoolCore);

            IAaveLendingPool(lendingPoolAddressProvider.getLendingPool())
                .deposit(intermediateToken, intermediateAmt, 0);

            intermediateToken = IAaveLendingPoolCore(aaveLendingPoolCore)
                .getReserveATokenAddress(intermediateToken);
        }

        return
            _zapIn(
                toVault,
                superVault,
                minYVTokens,
                intermediateToken,
                intermediateAmt
            );
    }

    function _zapIn(
        address toVault,
        address superVault,
        uint256 minYVTokens,
        address intermediateToken,
        uint256 intermediateAmt
    ) internal returns (uint256 tokensReceived) {
        // Deposit to Vault
        if (superVault == address(0)) {
            tokensReceived = _vaultDeposit(
                intermediateToken,
                intermediateAmt,
                toVault,
                minYVTokens,
                true
            );
        } else {
            uint256 intermediateYVTokens =
                _vaultDeposit(
                    intermediateToken,
                    intermediateAmt,
                    toVault,
                    0,
                    false
                );
            // deposit to super vault
            tokensReceived = _vaultDeposit(
                IYVault(superVault).token(),
                intermediateYVTokens,
                superVault,
                minYVTokens,
                true
            );
        }
    }

    function _vaultDeposit(
        address underlyingVaultToken,
        uint256 amount,
        address toVault,
        uint256 minTokensRec,
        bool shouldTransfer
    ) internal returns (uint256 tokensReceived) {
        _approveToken(underlyingVaultToken, toVault);

        uint256 iniYVaultBal = IERC20(toVault).balanceOf(address(this));
        IYVault(toVault).deposit(amount);
        tokensReceived = IERC20(toVault).balanceOf(address(this)).sub(
            iniYVaultBal
        );
        require(tokensReceived >= minTokensRec, "Err: High Slippage");

        if (shouldTransfer) {
            IERC20(toVault).safeTransfer(msg.sender, tokensReceived);
            emit zapIn(msg.sender, toVault, tokensReceived);
        }
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amtBought) {
        uint256 valueToSend;

        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget);
        }

        uint256 iniBal = _getBalance(toToken);
        (bool success, ) = _swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal.sub(iniBal);
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
