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
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "./ZapOutBaseV1.sol";

interface IYVault {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function getPricePerFullShare() external view returns (uint256);

    function token() external view returns (address);

    function decimals() external view returns (uint256);

    // V2
    function pricePerShare() external view returns (uint256);
}

interface IYVaultV1Registry {
    function getVaults() external view returns (address[] memory);

    function getVaultsLength() external view returns (uint256);
}

// -- Aave --
interface IAaveLendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);

    function getLendingPoolCore() external view returns (address payable);
}

interface IAToken {
    function redeem(uint256 _amount) external;

    function underlyingAssetAddress() external returns (address);
}

contract yVault_ZapOut_V2 is ZapOutBaseV1 {
    // calldata only accepted for approved zap contracts
    mapping(address => bool) public approvedTargets;

    IAaveLendingPoolAddressesProvider
        private constant lendingPoolAddressProvider =
        IAaveLendingPoolAddressesProvider(
            0x24a42fD28C976A61Df5D00D0599C34c4f90748c8
        );

    IYVaultV1Registry V1Registry =
        IYVaultV1Registry(0x3eE41C098f9666ed2eA246f4D2558010e59d63A0);

    event Zapout(
        address _toWhomToIssue,
        address _fromYVaultAddress,
        address _toTokenAddress,
        uint256 _tokensRecieved
    );

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    /**
    @notice Zap out in to a single token with permit
    @param fromVault Vault from which to remove liquidity
    @param amountIn Quantity of vault tokens to remove
    @param toToken Address of desired token
    @param isAaveUnderlying True if vault contains aave token
    @param minToTokens Minimum quantity of tokens to receive, reverts otherwise
    @param permitData Encoded permit data, which contains owner, spender, value, deadline, r,s,v values
    @param swapTarget Execution targets for swap or Zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return Quantity of tokens or ETH received
    */
    function ZapOutWithPermit(
        address fromVault,
        uint256 amountIn,
        address toToken,
        bool isAaveUnderlying,
        uint256 minToTokens,
        bytes calldata permitData,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external returns (uint256 tokensReceived) {
        // permit
        (bool success, ) = fromVault.call(permitData);
        require(success, "Could Not Permit");

        return
            ZapOut(
                fromVault,
                amountIn,
                toToken,
                isAaveUnderlying,
                minToTokens,
                swapTarget,
                swapData,
                affiliate
            );
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
    @return Quantity of tokens or ETH received
    */
    function ZapOut(
        address fromVault,
        uint256 amountIn,
        address toToken,
        bool isAaveUnderlying,
        uint256 minToTokens,
        address swapTarget,
        bytes memory swapData,
        address affiliate
    ) public stopInEmergency returns (uint256 tokensReceived) {
        require(
            approvedTargets[swapTarget] || swapTarget == address(0),
            "Target not Authorized"
        );

        IERC20(fromVault).safeTransferFrom(msg.sender, address(this), amountIn);

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
        tokensReceived = toTokenAmt.sub(totalGoodwillPortion);

        // send toTokens
        if (toToken == address(0)) {
            Address.sendValue(msg.sender, tokensReceived);
        } else {
            IERC20(toToken).safeTransfer(msg.sender, tokensReceived);
        }
    }

    function _vaultWithdraw(
        address fromVault,
        uint256 amount,
        address underlyingVaultToken
    ) internal returns (uint256 underlyingReceived) {
        uint256 iniUnderlyingBal = _getBalance(underlyingVaultToken);

        IYVault(fromVault).withdraw(amount);

        underlyingReceived = _getBalance(underlyingVaultToken).sub(
            iniUnderlyingBal
        );
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
            _approveToken(_fromTokenAddress, _swapTarget, _amount);
        }

        uint256 iniBal = _getBalance(toToken);

        (bool success, ) = _swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens 1");

        uint256 finalBal = _getBalance(toToken);

        require(finalBal > 0, "ERR: Swapped to wrong token");

        amtBought = finalBal.sub(iniBal);
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
                return
                    (liquidity.mul(vault.getPricePerFullShare())).div(10**18);
        }
        return (liquidity.mul(vault.pricePerShare())).div(10**vault.decimals());
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
