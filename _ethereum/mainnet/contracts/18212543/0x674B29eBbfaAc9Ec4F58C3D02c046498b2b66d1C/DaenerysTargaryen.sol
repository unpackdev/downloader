// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// tax: 0/0
// max buy and sell is 2% of the supplay
// max wallet balance is 3% of the supplay
// 5% of the supply for team
// CONTRACT RENOUNCED
// LOCKED LIQUIDITY 
// twitter: https://twitter.com/DaenerysETH20
// telegram: https://t.me/+44WXEcgXn7A1YjA0

import "./ERC20.sol";

contract DaenerysTargaryen is ERC20 {
    address public owner;
    address public liqOwner;
    uint256 public burnedTokens;
    uint256 public maxBuyAndSell;
    uint256 public maxWalletBalance;
    bool public openTradingBool;
    mapping(address => bool) public botsList;

    address public uniswapV2Pair;
    IUniswapV2Router public uniswapV2Router;
    IUniswapV2Factory public uniswapFactory;
    address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap Router

    constructor(uint256 initialSupply) ERC20("Daenerys Targaryen", "DT") {
        owner = msg.sender;
        liqOwner = msg.sender;
        maxBuyAndSell = (initialSupply * 2) / 100;
        maxWalletBalance = (initialSupply * 3) / 100;

        _mint(msg.sender, initialSupply);

        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(router);
        uniswapV2Router = _uniswapV2Router;
        IUniswapV2Factory _uniswapFactory = IUniswapV2Factory(
            uniswapV2Router.factory()
        );
        uniswapFactory = _uniswapFactory;

    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this func");
        _;
    }

    function _beforeTokenTransfer(
        address _from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!botsList[_from] && !botsList[to], "run away bot");

        if (msg.sender == liqOwner || _from == liqOwner || to == liqOwner) {
            return;
        }
        if (!openTradingBool) {
            revert("Trading is not open");
        }

        require(amount <= maxBuyAndSell, "amount is too higt");

        if (_from == uniswapV2Pair) {
            require(
                balanceOf(to) + amount <= maxWalletBalance,
                "wallet is too big"
            );
        }
    }

    function removeOwnership() external onlyOwner {
        owner = address(0);
    }

    function addToBotsList(address botAddress) external onlyOwner {
        botsList[botAddress] = true;
    }

    function removeFromBotsList(address botAddress) external onlyOwner {
        botsList[botAddress] = false;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        burnedTokens += amount;
        maxBuyAndSell = (totalSupply() * 2) / 100;
        maxWalletBalance = (totalSupply() * 3) / 100;
    }

    function setPair() external onlyOwner {
        address ethAddres = uniswapV2Router.WETH();
        uniswapV2Pair = uniswapFactory.getPair(ethAddres, address(this));
    }

    function openTrading() external onlyOwner {
        openTradingBool = true;
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router {
    function factory() external returns (address);

    function WETH() external pure returns (address);
}
