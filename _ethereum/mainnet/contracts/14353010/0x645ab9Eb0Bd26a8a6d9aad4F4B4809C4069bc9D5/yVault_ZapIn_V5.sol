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

///@author Zapper
///@notice This contract adds liquidity to Yearn Vaults using ETH or ERC20 Tokens.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "./ZapInBaseV3_1.sol";

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

interface IYearnPartnerTracker {
    function deposit(
        address vault,
        address partnerId,
        uint256 amount
    ) external returns (uint256);
}

interface IYVault {
    function deposit(uint256) external;

    function withdraw(uint256) external;

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

contract yVault_ZapIn_V5 is ZapInBaseV3_1 {
    using SafeERC20 for IERC20;

    IAaveLendingPoolAddressesProvider
        private constant lendingPoolAddressProvider =
        IAaveLendingPoolAddressesProvider(
            0x24a42fD28C976A61Df5D00D0599C34c4f90748c8
        );

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IYearnPartnerTracker private constant yearnPartnerTracker =
        IYearnPartnerTracker(0x8ee392a4787397126C163Cb9844d7c447da419D8);
    address private constant yveCRV =
        0xc5bDdf9843308380375a611c18B50Fb9341f502A;

    event zapIn(address sender, address pool, uint256 tokensRec);

    constructor(
        address _curveZapIn,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) ZapBaseV2_1(_goodwill, _affiliateSplit) {
        // Curve ZapIn
        approvedTargets[_curveZapIn] = true;
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

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
        @return tokensReceived Quantity of Vault tokens received
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
        if (toVault == yveCRV) {
            _approveToken(underlyingVaultToken, toVault);

            uint256 iniYVaultBal = IERC20(toVault).balanceOf(address(this));
            IYVault(toVault).deposit(amount);
            tokensReceived =
                IERC20(toVault).balanceOf(address(this)) -
                iniYVaultBal;
        } else {
            _approveToken(underlyingVaultToken, address(yearnPartnerTracker));
            tokensReceived = yearnPartnerTracker.deposit(
                toVault,
                ZapperAdmin,
                amount
            );
        }

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
        bytes memory swapData
    ) internal returns (uint256 amtBought) {
        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget);
        }

        uint256 iniBal = _getBalance(toToken);
        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal - iniBal;
    }
}
