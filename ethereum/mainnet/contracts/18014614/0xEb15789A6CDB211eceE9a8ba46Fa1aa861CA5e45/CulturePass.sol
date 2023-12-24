/**
    Website  : https://culturepass.vip/
    Telegram : https://t.me/Culturepass

    @Description

    🎉 CONGRATULATIONS - YOU MADE IT 🎉

    Welcome to CULTURE PASS Token! 🌟

    🪙 CULTURE PASS token is a gateway to riches. Holding CULTURE PASS allows the holder to be the first to buy 
    💎🚀 -- the secretive meme coin that has been in the works for months. Before launching 💎🚀, we wanted to ensure that 
    only true investors could get in early. Snipers and bots have ruined stealth launches for everyone, but we've devised 
    a way to get rid of them. 💪🤖❌

    Holding 1 CULTURE PASS token allows the holder to buy 💎🚀 in the first 4 BLOCKS ⛓️ of launch (FIRST 60 SECONDS ⏱️).
    Anyone's wallet NOT holding CULTURE PASS will NOT be able to buy. The 💎🚀 contract is programmed this way. 🔒📝

    Fear not, Anon. CULTURE PASS price will not exceed $16 💰 for the last buyer; the first buyer will pay 10 cents 🪙 
    and the price will increase until it hits $16 max. 📈💹

    This brilliant new method of launching stealth puts the power back in the hands of the investors 👥💼, and out of the 
    hands of the dirty sniper bots. 🤖🎯 We hope to start a revolution 🌍🚀, one where meme coin trading is fair, launches 
    are clean, and snipers and bots can't destroy a project before it takes off. 🙌🛡️🚫

**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Dependencies2.sol";

contract CulturePass is ERC20, Ownable {
    using Address for address payable;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public maxWalletLimit;

    constructor() ERC20("CONGRATULATIONS YOU MADE IT", "CULTUREPASS") {
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap Mainnet & Testnet for ethereum network

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        _mint(msg.sender, 500 * (10**decimals()));
        maxWalletLimit = 1 * (10**decimals());
    }

    function reedemOtherTokens(address token) external onlyOwner{
        if (token == address(0x0)) {
            payable(owner()).sendValue(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(owner(), balance);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0x0), "ERC20: transfer from the zero address");
        require(to != address(0x0), "ERC20: transfer to the zero address");

        if (from != owner() && to != uniswapV2Pair) {
            require(
                balanceOf(to) + amount <= maxWalletLimit,
                "You are exceeding maxWalletLimit"
            );
        }

        if (from == uniswapV2Pair) {
            require(
                amount <= maxWalletLimit,
                "You are exceeding maxWalletLimit"
            );
            require(
                balanceOf(to) + amount <= maxWalletLimit,
                "You are exceeding maxWalletLimit"
            );
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        super._transfer(from, to, amount);
    }
}
