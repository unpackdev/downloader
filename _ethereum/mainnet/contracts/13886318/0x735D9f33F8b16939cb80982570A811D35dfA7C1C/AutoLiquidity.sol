// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";

import "./ERC20Extends.sol";
import "./UniV3PMExtends.sol";
import "./UniV3Liquidity.sol";
import "./UniV3LiquidityStaker.sol";

pragma abicoder v2;
/// @title Position Management
/// @notice Provide asset operation functions, allow authorized identities to perform asset operations, and achieve the purpose of increasing the net value of the fund
contract AutoLiquidity is UniV3Liquidity, UniV3LiquidityStaker {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    //Contract binding status
    bool public bound;
    //Fund purchase and redemption token
    IERC20 public ioToken;
    //Fund contract address
    address public fund;
    //Underlying asset
    EnumerableSet.AddressSet internal underlyings;

    /// @notice Binding funds and subscription redemption token
    /// @dev Only bind once and cannot be modified
    /// @param _fund Fund address
    /// @param _ioToken Subscription and redemption token
    function bind(address _fund, address _ioToken) external onlyGovernance {
        require(!bound, "already bind");
        fund = _fund;
        ioToken = IERC20(_ioToken);
        bound = true;
    }

    //Only allow fund contract access
    modifier onlyFund() {
        require(extAuthorize(), "!fund");
        _;
    }

    /// @notice ext authorize
    function extAuthorize() internal override view returns (bool){
        return msg.sender == fund;
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

    /// @notice Withdraw asset
    /// @dev Only fund contract can withdraw asset
    /// @param to Withdraw address
    /// @param amount Withdraw amount
    /// @param scale Withdraw percentage
    function withdraw(address to, uint256 amount, uint256 scale) external onlyFund {
        uint256 surplusAmount = ioToken.balanceOf(address(this));
        if (surplusAmount < amount) {
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
            for (uint256 i = 0; i < underlyings.length(); i++) {
                address token = underlyings.at(i);
                uint256 balance = IERC20(token).balanceOf(address(this));
                uint256 decreaseAmount = balance.sub(balances[i]);
                uint256 swapAmount = withdrawAmounts[i].add(decreaseAmount);
                if (token != address(ioToken) && swapAmount > 0) {
                    exactInput(token, address(ioToken), swapAmount, 0);
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
    /// @dev Only fund contract can withdraw underlying asset
    /// @param to Withdraw address
    /// @param scale Withdraw percentage
    function withdrawOfUnderlying(address to, uint256 scale) external onlyFund {
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
            uint256 transferAmount = withdrawAmounts[i].add(decreaseAmount);
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

    /// @notice staker liquidity asset
    /// @dev This function calculates liquidity asset
    /// @return liquidity asset
    function stakerAssets() public view returns (uint256){
        uint256 total;
        address ioTokenAddr = address(ioToken);
        uint256 length = stakers.length();
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = stakers.at(i);
            total = total.add(calcLiquidityAssets(tokenId, ioTokenAddr));
        }
        return total;
    }
}
