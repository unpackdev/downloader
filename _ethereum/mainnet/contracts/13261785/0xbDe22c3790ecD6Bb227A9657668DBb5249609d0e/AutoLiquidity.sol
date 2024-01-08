// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";

import "./IVault.sol";
import "./ERC20Extends.sol";
import "./UniV3PMExtends.sol";
import "./SmartPoolStorage.sol";
import "./UniV3Liquidity.sol";

pragma abicoder v2;
/// @title Position Management
/// @notice Provide asset operation functions, allow authorized identities to perform asset operations, and achieve the purpose of increasing the net value of the Vault
contract AutoLiquidity is UniV3Liquidity {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UniV3SwapExtends for mapping(address => mapping(address => bytes));

    //Vault purchase and redemption token
    IERC20 public ioToken;
    //Vault contract address
    IVault public vault;
    //Underlying asset
    EnumerableSet.AddressSet internal underlyings;

    event TakeFee(SmartPoolStorage.FeeType ft, address owner, uint256 fee);

    /// @notice Binding vaults and subscription redemption token
    /// @dev Only bind once and cannot be modified
    /// @param _vault Vault address
    /// @param _ioToken Subscription and redemption token
    function bind(address _vault, address _ioToken) external onlyGovernance {
        vault = IVault(_vault);
        ioToken = IERC20(_ioToken);
    }

    //Only allow vault contract access
    modifier onlyVault() {
        require(extAuthorize(), "!vault");
        _;
    }

    /// @notice ext authorize
    function extAuthorize() internal override view returns (bool){
        return msg.sender == address(vault);
    }

    /// @notice in work tokenId array
    /// @dev read in works NFT array
    /// @return tokenIds NFT array
    function worksPos() public view returns (uint256[] memory tokenIds){
        uint256 length = works.length();
        tokenIds = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = works.at(i);
        }
    }

    /// @notice in underlyings token address array
    /// @dev read in underlyings token address array
    /// @return tokens address array
    function getUnderlyings() public view returns (address[] memory tokens){
        uint256 length = underlyings.length();
        tokens = new address[](length);
        for (uint256 i = 0; i < underlyings.length(); i++) {
            tokens[i] = underlyings.at(i);
        }
    }


    /// @notice Set the underlying asset token address
    /// @dev Only allow the governance identity to set the underlying asset token address
    /// @param ts The underlying asset token address array to be added
    function setUnderlyings(address[] memory ts) public onlyGovernance {
        for (uint256 i = 0; i < ts.length; i++) {
            if (!underlyings.contains(ts[i])) {
                underlyings.add(ts[i]);
            }
        }
    }

    /// @notice Delete the underlying asset token address
    /// @dev Only allow the governance identity to delete the underlying asset token address
    /// @param ts The underlying asset token address array to be deleted
    function removeUnderlyings(address[] memory ts) public onlyGovernance {
        for (uint256 i = 0; i < ts.length; i++) {
            if (underlyings.contains(ts[i])) {
                underlyings.remove(ts[i]);
            }
        }
    }

    /// @notice swap after handle
    /// @param tokenOut token address
    /// @param amountOut token amount
    function swapAfter(
        address tokenOut,
        uint256 amountOut) internal override {
        uint256 fee = vault.calcRatioFee(SmartPoolStorage.FeeType.TURNOVER_FEE, amountOut);
        if (tokenOut != address(ioToken) && fee > 0) {
            fee = swapRoute.exactInput(tokenOut, address(ioToken), fee, address(this), 0);
        }
        if (fee > 0) {
            address rewards=getRewards();
            ioToken.safeTransfer(rewards, fee);
            emit TakeFee(SmartPoolStorage.FeeType.TURNOVER_FEE, rewards, fee);
        }
    }

    /// @notice collect after handle
    /// @param token0 token address
    /// @param token1 token address
    /// @param amount0 token amount
    /// @param amount1 token amount
    function collectAfter(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1) internal override {
        uint256 fee0 = vault.calcRatioFee(SmartPoolStorage.FeeType.TURNOVER_FEE, amount0);
        uint256 fee1 = vault.calcRatioFee(SmartPoolStorage.FeeType.TURNOVER_FEE, amount1);
        if (token0 != address(ioToken) && fee0 > 0) {
            fee0 = swapRoute.exactInput(token0, address(ioToken), fee0, address(this), 0);
        }
        if (token1 != address(ioToken) && fee1 > 0) {
            fee1 = swapRoute.exactInput(token1, address(ioToken), fee1, address(this), 0);
        }
        uint256 fee = fee0.add(fee1);
        if (fee > 0) {
            address rewards=getRewards();
            ioToken.safeTransfer(rewards, fee);
            emit TakeFee(SmartPoolStorage.FeeType.TURNOVER_FEE, rewards, fee);
        }
    }

    /// @notice Asset transfer used to upgrade the contract
    /// @param to address
    function withdrawAll(address to) external onlyGovernance {
        for (uint256 i = 0; i < underlyings.length(); i++) {
            IERC20 token = IERC20(underlyings.at(i));
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                token.safeTransfer(to, balance);
            }
        }
    }

    /// @notice Withdraw asset
    /// @dev Only vault contract can withdraw asset
    /// @param to Withdraw address
    /// @param amount Withdraw amount
    /// @param scale Withdraw percentage
    function withdraw(address to, uint256 amount, uint256 scale) external onlyVault {
        uint256 surplusAmount = ioToken.balanceOf(address(this));
        if (surplusAmount < amount) {
            _decreaseLiquidityByScale(scale);
            for (uint256 i = 0; i < underlyings.length(); i++) {
                address token = underlyings.at(i);
                uint256 balance = IERC20(token).balanceOf(address(this));
                if (token != address(ioToken) && balance > 0) {
                    exactInput(token, address(ioToken), balance, 0);
                }
            }
        }
        surplusAmount = ioToken.balanceOf(address(this));
        if (surplusAmount < amount) {
            amount = surplusAmount;
        }
        ioToken.safeTransfer(to, amount);
    }

    /// @notice Withdraw underlying asset
    /// @dev Only vault contract can withdraw underlying asset
    /// @param to Withdraw address
    /// @param scale Withdraw percentage
    function withdrawOfUnderlying(address to, uint256 scale) external onlyVault {
        uint256 length = underlyings.length();
        uint256[] memory balances = new uint256[](length);
        uint256[] memory withdrawAmounts = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            address token = underlyings.at(i);
            uint256 balance = IERC20(token).balanceOf(address(this));
            balances[i] = balance;
            withdrawAmounts[i] = balance.mul(scale).div(1e18);
        }
        _decreaseLiquidityByScale(scale);
        for (uint256 i = 0; i < length; i++) {
            address token = underlyings.at(i);
            uint256 balance = IERC20(token).balanceOf(address(this));
            uint256 decreaseAmount = balance.sub(balances[i]);
            uint256 addAmount = decreaseAmount.mul(scale).div(1e18);
            uint256 transferAmount = withdrawAmounts[i].add(addAmount);
            IERC20(token).safeTransfer(to, transferAmount);
        }
    }

    /// @notice Decrease liquidity by scale
    /// @dev Decrease liquidity by provided scale
    /// @param scale Scale of the liquidity
    function _decreaseLiquidityByScale(uint256 scale) internal {
        uint256 length = works.length();
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = works.at(i);
            (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint128 liquidity,
            ,
            ,
            ,
            ) = UniV3PMExtends.PM.positions(tokenId);
            if (liquidity > 0) {
                uint256 _decreaseLiquidity = uint256(liquidity).mul(scale).div(1e18);
                (uint256 amount0, uint256 amount1) = decreaseLiquidity(tokenId, uint128(_decreaseLiquidity), 0, 0);
                collect(tokenId, uint128(amount0), uint128(amount1));
            }
        }
    }

    /// @notice Total asset
    /// @dev This function calculates the net worth or AUM
    /// @return Total asset
    function assets() public view returns (uint256){
        uint256 total = idleAssets();
        total = total.add(liquidityAssets());
        return total;
    }

    /// @notice idle asset
    /// @dev This function calculates idle asset
    /// @return idle asset
    function idleAssets() public view returns (uint256){
        uint256 total;
        for (uint256 i = 0; i < underlyings.length(); i++) {
            address token = underlyings.at(i);
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (token == address(ioToken)) {
                total = total.add(balance);
            } else {
                uint256 _estimateAmountOut = estimateAmountOut(token, address(ioToken), balance);
                total = total.add(_estimateAmountOut);
            }
        }
        return total;
    }

    /// @notice at work liquidity asset
    /// @dev This function calculates liquidity asset
    /// @return liquidity asset
    function liquidityAssets() public view returns (uint256){
        uint256 total;
        address ioTokenAddr = address(ioToken);
        uint256 length = works.length();
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = works.at(i);
            total = total.add(calcLiquidityAssets(tokenId, ioTokenAddr));
        }
        return total;
    }
}
