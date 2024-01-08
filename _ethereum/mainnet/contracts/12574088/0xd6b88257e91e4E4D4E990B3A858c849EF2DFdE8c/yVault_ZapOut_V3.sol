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
///@notice This contract removes liquidity from yEarn Vaults to ETH or ERC20 Tokens.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "./ZapOutBaseV3.sol";

interface IWETH {
    function withdraw(uint256 wad) external;
}

interface IYVault {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function getPricePerFullShare() external view returns (uint256);

    function token() external view returns (address);

    function decimals() external view returns (uint256);

    // V2
    function pricePerShare() external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    function name() external pure returns (string memory);

    function nonces(address owner) external view returns (uint256);
}

interface IYVaultV1Registry {
    function getVaults() external view returns (address[] memory);

    function getVaultsLength() external view returns (uint256);
}

// -- Aave --
interface IAToken {
    function redeem(uint256 _amount) external;

    function underlyingAssetAddress() external returns (address);
}

contract yVault_ZapOut_V3_0_1 is ZapOutBaseV3 {
    using SafeERC20 for IERC20;

    IYVaultV1Registry V1Registry =
        IYVaultV1Registry(0x3eE41C098f9666ed2eA246f4D2558010e59d63A0);

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant permitAllowance = 79228162514260000000000000000;

    event zapOut(
        address sender,
        address pool,
        address token,
        uint256 tokensRec
    );

    constructor(
        address _curveZapOut,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) ZapBaseV2(_goodwill, _affiliateSplit) {
        // Curve ZapOut
        approvedTargets[_curveZapOut] = true;
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    /**
        @notice Zap out in to a single token with permit
        @param fromVault Vault from which to remove liquidity
        @param amountIn Quantity of vault tokens to remove
        @param toToken Address of desired token
        @param isAaveUnderlying True if vault contains aave token
        @param minToTokens Minimum quantity of tokens to receive, reverts otherwise
        @param permitSig Encoded permit hash, which contains r,s,v values
        @param swapTarget Execution targets for swap or Zap
        @param swapData DEX or Zap data
        @param affiliate Affiliate address
        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
        @return tokensReceived Quantity of tokens or ETH received
    */
    function ZapOutWithPermit(
        address fromVault,
        uint256 amountIn,
        address toToken,
        bool isAaveUnderlying,
        uint256 minToTokens,
        bytes calldata permitSig,
        address swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external returns (uint256 tokensReceived) {
        // permit
        _permit(fromVault, permitAllowance, permitSig);

        return
            ZapOut(
                fromVault,
                amountIn,
                toToken,
                isAaveUnderlying,
                minToTokens,
                swapTarget,
                swapData,
                affiliate,
                shouldSellEntireBalance
            );
    }

    function _permit(
        address fromVault,
        uint256 amountIn,
        bytes memory permitSig
    ) internal {
        bool success =
            IYVault(fromVault).permit(
                msg.sender,
                address(this),
                amountIn,
                deadline,
                permitSig
            );
        require(success, "Could Not Permit");
    }

    /**
        @notice Zap out in to a single token with permit
        @param fromVault Vault from which to remove liquidity
        @param amountIn Quantity of vault tokens to remove
        @param toToken Address of desired token
        @param isAaveUnderlying True if vault contains aave token
        @param minToTokens Minimum quantity of tokens to receive, reverts otherwise
        @param swapTarget Execution targets for swap or Zap
        @param swapData DEX or Zap data
        @param affiliate Affiliate address
        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
        @return tokensReceived Quantity of tokens or ETH received
    */
    function ZapOut(
        address fromVault,
        uint256 amountIn,
        address toToken,
        bool isAaveUnderlying,
        uint256 minToTokens,
        address swapTarget,
        bytes memory swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) public stopInEmergency returns (uint256 tokensReceived) {
        _pullTokens(fromVault, amountIn, shouldSellEntireBalance);

        // get underlying token from vault
        address underlyingToken = IYVault(fromVault).token();
        uint256 underlyingTokenReceived =
            _vaultWithdraw(fromVault, amountIn, underlyingToken);

        // swap to toToken
        uint256 toTokenAmt;

        if (isAaveUnderlying) {
            address underlyingAsset =
                IAToken(underlyingToken).underlyingAssetAddress();
            // unwrap atoken
            IAToken(underlyingToken).redeem(underlyingTokenReceived);

            // aTokens are 1:1
            if (underlyingAsset == toToken) {
                toTokenAmt = underlyingTokenReceived;
            } else {
                toTokenAmt = _fillQuote(
                    underlyingAsset,
                    toToken,
                    underlyingTokenReceived,
                    swapTarget,
                    swapData
                );
            }
        } else {
            toTokenAmt = _fillQuote(
                underlyingToken,
                toToken,
                underlyingTokenReceived,
                swapTarget,
                swapData
            );
        }
        require(toTokenAmt >= minToTokens, "Err: High Slippage");

        uint256 totalGoodwillPortion =
            _subtractGoodwill(toToken, toTokenAmt, affiliate, true);
        tokensReceived = toTokenAmt - totalGoodwillPortion;

        // send toTokens
        if (toToken == address(0)) {
            Address.sendValue(payable(msg.sender), tokensReceived);
        } else {
            IERC20(toToken).safeTransfer(msg.sender, tokensReceived);
        }
        emit zapOut(msg.sender, fromVault, toToken, tokensReceived);
    }

    function _vaultWithdraw(
        address fromVault,
        uint256 amount,
        address underlyingVaultToken
    ) internal returns (uint256 underlyingReceived) {
        uint256 iniUnderlyingBal = _getBalance(underlyingVaultToken);

        IYVault(fromVault).withdraw(amount);

        underlyingReceived =
            _getBalance(underlyingVaultToken) -
            iniUnderlyingBal;
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

        if (_fromTokenAddress == wethTokenAddress && toToken == address(0)) {
            IWETH(wethTokenAddress).withdraw(_amount);
            return _amount;
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget, _amount);
        }

        uint256 iniBal = _getBalance(toToken);
        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        require(finalBal > 0, "ERR: Swapped to wrong token");
        amtBought = finalBal - iniBal;
    }

    /**
        @notice Utility function to determine the quantity of underlying tokens removed from vault
        @param fromVault Yearn vault from which to remove liquidity
        @param liquidity Quantity of vault tokens to remove
        @return Quantity of underlying LP or token removed
    */
    function removeLiquidityReturn(address fromVault, uint256 liquidity)
        external
        view
        returns (uint256)
    {
        IYVault vault = IYVault(fromVault);

        address[] memory V1Vaults = V1Registry.getVaults();

        for (uint256 i = 0; i < V1Registry.getVaultsLength(); i++) {
            if (V1Vaults[i] == fromVault)
                return (liquidity * (vault.getPricePerFullShare())) / (10**18);
        }
        return (liquidity * (vault.pricePerShare())) / (10**vault.decimals());
    }
}
