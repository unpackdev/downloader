
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// Openzeppelin imports
import "./AccessControl.sol";
import "./ERC20.sol";

/// Yearn imports
import "./VaultInterface.sol";

/// Local imports
import "./IStrategy.sol";

/// UNISWAP imports
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";



/**
 * @title Implementation of the Yearn Strategy.
 *
 */
contract YearnStrategy is IStrategy {


    /// Public override member functions
    function decimals() public pure virtual override returns (uint256) {

        return 0;
    }

    function vaultAddress() public pure virtual override returns (address) {

        return 0x0000000000000000000000000000000000000000;
    }

    function vaultTokenAddress() public pure virtual override returns (address) {

        return 0x0000000000000000000000000000000000000000;
    }

    function farm(address erc20Token_, uint256 amount_) public override returns (uint256) {

        require(amount_ <= ERC20(erc20Token_).balanceOf(address(this)), "Insufficient balance");
        uint256 vaultTokenAmount = amount_;
        if (erc20Token_ != vaultTokenAddress()) {
            uint256 amountBefore = ERC20(vaultTokenAddress()).balanceOf(address(this));
            _swap(erc20Token_, vaultTokenAddress(), address(this), amount_);
            vaultTokenAmount = ERC20(vaultTokenAddress()).balanceOf(address(this)) - amountBefore;
        }
        ERC20(vaultTokenAddress()).approve(vaultAddress(), vaultTokenAmount);
        VaultInterface(vaultAddress()).deposit(vaultTokenAmount); // TODO take return value
        return vaultTokenAmount;
    }

    function estimateReward(address addr) public view override returns (uint256) {

        return (VaultInterface(vaultAddress()).balanceOf(addr) *
                VaultInterface(vaultAddress()).pricePerShare()) / (10**decimals());
    }

    function takeReward(address to_, address expectedToken_, uint256 amount_) public override {

        address tokenAddress = vaultTokenAddress();
        if (tokenAddress == expectedToken_) {
            VaultInterface(vaultAddress()).withdraw(amount_, to_);
        } else {
            VaultInterface(vaultAddress()).withdraw(amount_, address(this));
            _swap(tokenAddress, expectedToken_, to_, amount_);
        }
    }

    function takeReward(address to_) public override {

        VaultInterface(vaultAddress()).withdraw(type(uint256).max, to_);
    }

    function _swap(address fromToken_, address toToken_, address to_, uint256 amount_) private {

        address uniswapFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        require(IUniswapV2Factory(uniswapFactory).getPair(fromToken_, toToken_) != address(0x0), "There is no pair");
        address uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IERC20(fromToken_).approve(uniswapRouter, amount_);
        address[] memory path = new address[](2);
        path[0] = fromToken_;
        path[1] = toToken_;
        IUniswapV2Router02(uniswapRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                            amount_, 0, path, to_, block.timestamp);
    }
}
