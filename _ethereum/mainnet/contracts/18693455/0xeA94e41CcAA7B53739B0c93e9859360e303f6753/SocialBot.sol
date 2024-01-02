//telegram: https://t.me/socialbottoken
//twitter: https://twitter.com/SocialBotERC
//website: https://socialboterc.com/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract SocialBot is ERC20, Ownable 
{
    using SafeMath for uint256;
    
    address private deployerWallet;
    mapping(address => bool) private bots;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public pair;

    string private constant _name       = "SocialBot";
    string private constant _symbol     = "SOCBOT";
    
    uint256 public supply               = 10_000_000 ether;
    uint256 public maxTransaction       = 200_000 ether;
    uint256 public maxWallet            = 400_000 ether;

    uint256 public sellTax              = 5;

    bool public tradingOpen             = false;

    address public router               = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public marketing            = 0x39c6170D4b193636fcA78433D7310DbB6C36fcD8;

    constructor() ERC20(_name, _symbol) 
    {
        uniswapV2Router = IUniswapV2Router02(router);

        pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        deployerWallet = payable(_msgSender());

        _mint(msg.sender,  supply);
    }

    function setTaxation(
        uint _taxPercentage)
        external
        onlyOwner 
    {
        require(_taxPercentage <= 10);
        sellTax = _taxPercentage;    
    }

    function openTrading() external onlyOwner() 
    {
        require(!tradingOpen,"Trading is already open");        
        tradingOpen = true;
    }

    function addBots(address[] memory bots_) public onlyOwner 
    {
        for (uint256 i = 0; i < bots_.length; i++) 
        {
            bots[bots_[i]] = true;
        }
    }

    function removeBots(address[] memory notbot) public onlyOwner 
    {
        for (uint256 i = 0; i < notbot.length; i++) 
        {
            bots[notbot[i]] = false;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount) 
        override 
        internal 
        virtual 
    {
        if (from != owner() && to != owner()) 
        {
            require(!bots[from] && !bots[to]);
            require(tradingOpen, "Trading is not active.");
            require(amount <= maxTransaction, "Buy transfer amount exceeds the maxTransaction.");

            if (from == pair) 
            {   
                require(amount + super.balanceOf(to) <= maxWallet, "Max wallet exceeded");
            }   
        }
    }

    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount) 
        public 
        override 
        returns (bool) 
    {
        if (sender != address(this) && recipient == pair) 
        {
            // take tax on sale
            (uint net, uint tax) = _calcTax(amount);
            _takeFee(sender, tax);
            super.transferFrom(sender, recipient, net);
        } 
        else 
        {
            super.transferFrom(sender, recipient, amount);
        }

        return true;
    }

    function _takeFee(
        address from, 
        uint amount) 
        private
    {
        _transfer(from, address(this), amount);
    }

    function _calcTax(
        uint amount) 
        private 
        view 
        returns(uint, uint)
    {
        uint256 taxAmount = amount.mul(sellTax).div(100);
        uint256 netAmount = amount.sub(taxAmount);
        return (netAmount, taxAmount);
    }

    function sendTaxes() external
    {
        _transfer(address(this), marketing, balanceOf(address(this)));
    }
}