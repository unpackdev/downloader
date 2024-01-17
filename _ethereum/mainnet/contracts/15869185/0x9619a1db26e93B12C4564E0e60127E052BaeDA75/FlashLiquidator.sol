// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "./IEulerDToken.sol";
import "./IEulerMarkets.sol";
import "./IEulerFlashLoanReceiver.sol";
import "./NotionalProxy.sol";
import "./CErc20Interface.sol";
import "./CEtherInterface.sol";
import "./WETH9.sol";
import "./TokenUtils.sol";
import "./Constants.sol";
import "./Types.sol";
import "./BoringOwnable.sol";
import "./Deployments.sol";

contract FlashLiquidator is IEulerFlashLoanReceiver, BoringOwnable {
    using TokenUtils for IERC20;

    NotionalProxy public immutable NOTIONAL;
    address public immutable EULER;
    IEulerMarkets public immutable MARKETS;
    mapping(address => address) internal underlyingToAsset;

    struct LiquidationParams {
        uint16 currencyId;
        address account;
        address vault;
        bytes redeemData;
    }

    constructor(NotionalProxy notional_, address euler_, IEulerMarkets markets_) {
        NOTIONAL = notional_;
        EULER = euler_;
        MARKETS = markets_;
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function enableCurrencies(uint16[] calldata currencies) external onlyOwner {
        for (uint256 i; i < currencies.length; i++) {
            (Token memory assetToken, Token memory underlyingToken) = NOTIONAL.getCurrency(currencies[i]);
            IERC20(assetToken.tokenAddress).checkApprove(address(NOTIONAL), type(uint256).max);
            if (underlyingToken.tokenAddress == Constants.ETH_ADDRESS) {
                IERC20(address(Deployments.WETH)).checkApprove(address(EULER), type(uint256).max);
                underlyingToAsset[address(Deployments.WETH)] = assetToken.tokenAddress;
            } else {
                IERC20(underlyingToken.tokenAddress).checkApprove(address(EULER), type(uint256).max);
                IERC20(underlyingToken.tokenAddress).checkApprove(assetToken.tokenAddress, type(uint256).max);
                underlyingToAsset[underlyingToken.tokenAddress] = assetToken.tokenAddress;
            }
        }
    }

    function estimateProfit(
        address asset,
        uint256 amount,
        LiquidationParams calldata params
    ) external onlyOwner returns (uint256) {
        uint256 balance = IERC20(asset).balanceOf(address(this));
        IEulerDToken dToken = IEulerDToken(MARKETS.underlyingToDToken(asset));
        dToken.flashLoan(amount, abi.encode(asset, amount, false, params));
        return IERC20(asset).balanceOf(address(this)) - balance;
    }

    function flashLiquidate(
        address asset,
        uint256 amount,
        LiquidationParams calldata params
    ) external {
        IEulerDToken dToken = IEulerDToken(MARKETS.underlyingToDToken(asset));
        dToken.flashLoan(amount, abi.encode(asset, amount, true, params));
    }

    function onFlashLoan(bytes memory data) external override {
        require(msg.sender == address(EULER));

        (
            address asset, 
            uint256 amount, 
            bool withdraw,
            LiquidationParams memory params
        ) = abi.decode(data, (address, uint256, bool, LiquidationParams));

        address assetToken = underlyingToAsset[asset];

        // Mint CToken
        if (params.currencyId == Constants.ETH_CURRENCY_ID) {
            Deployments.WETH.withdraw(amount);
            CEtherInterface(assetToken).mint{value: amount}();
        } else {
            CErc20Interface(assetToken).mint(amount);
        }

        {
            (
                /* int256 collateralRatio */,
                /* int256 minCollateralRatio */,
                int256 maxLiquidatorDepositAssetCash,
                /* uint256 vaultSharesToLiquidator */
            ) = NOTIONAL.getVaultAccountCollateralRatio(params.account, params.vault);
            
            require(maxLiquidatorDepositAssetCash > 0);

            NOTIONAL.deleverageAccount(
                params.account, 
                params.vault, 
                address(this), 
                uint256(maxLiquidatorDepositAssetCash), 
                false, 
                params.redeemData
            );
        }

        // Redeem CToken
        {
            uint256 balance = IERC20(assetToken).balanceOf(address(this));
            if (balance > 0) {
                CErc20Interface(assetToken).redeem(balance);
                if (params.currencyId == Constants.ETH_CURRENCY_ID) {
                    _wrapETH();
                }
            }
        }

        if (withdraw) {
            _withdrawToOwner(asset, IERC20(asset).balanceOf(address(this)) - amount);
        }

        IERC20(asset).transfer(msg.sender, amount); // repay
    }

    function _withdrawToOwner(address token, uint256 amount) private {
        if (amount == type(uint256).max) {
            amount = IERC20(token).balanceOf(address(this));
        }
        if (amount > 0) {
            IERC20(token).checkTransfer(owner, amount);
        }
    }

    function _wrapETH() private {
        Deployments.WETH.deposit{value: address(this).balance}();
    }

    function withdrawToOwner(address token, uint256 amount) external onlyOwner {
        _withdrawToOwner(token, amount);
    }

    function wrapETH() external onlyOwner {
        _wrapETH();
    }

    receive() external payable {} 
}
