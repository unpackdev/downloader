// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract SpecialWolf is ERC20, Ownable {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public maxAmountPerWallet;
    uint256 public maxTxnAmount;
    address private _uniPairAddress;

    uint256 _totalSupply = 1 * 1e12 * 1e18; // 1 Trillion

    constructor() ERC20("Special Wolf", "SPECIALWOLF") {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        _uniPairAddress = address(uniswapV2Pair);

        maxAmountPerWallet = _totalSupply * 10 / 100; // allowed only 10% of total supply for each wallet
        maxTxnAmount = _totalSupply * 4 / 100; // 2% maxTransaction Amount at a time

        _mint(msg.sender, _totalSupply);
    }

    function setMaxWalletAmount(uint256 _newPercentage) external onlyOwner
    {
        uint256 newAmount = _newPercentage * _totalSupply / 1000;
        require(newAmount >= maxAmountPerWallet, "Set new amount higher than previous one.");
        maxAmountPerWallet = newAmount;
    }

    function setMaxTxnAmount(uint256 _newPercentage) external onlyOwner
    {
        uint256 newAmount = _newPercentage * _totalSupply / 1000;
        require(newAmount >= maxTxnAmount, "Set new amount higher than previous one.");
        maxTxnAmount = newAmount;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {

        if (_from == _uniPairAddress && _from != owner() && _to != owner()) {
            require(_amount <= maxTxnAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
            require(_amount + balanceOf(_to) <= maxAmountPerWallet, "Max wallet exceeded");
        }
            
        if (_to == _uniPairAddress && _from != owner() && _to != owner()) {
            require(_amount <= maxTxnAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
        }

        super._transfer(_from, _to, _amount);
    }
}