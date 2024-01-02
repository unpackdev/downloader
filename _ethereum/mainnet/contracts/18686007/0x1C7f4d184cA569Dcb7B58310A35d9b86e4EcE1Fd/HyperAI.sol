//telegram: https://t.me/hypex_TG
//website: https://www.hyperplay.xyz/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

contract HyperAI is ERC20, Ownable {
    using SafeMath for uint256;
    
    address private deployerWallet;

    string private constant _name = "HyperAI";
    string private constant _symbol = "HYPAI";
    mapping(address => bool) private bots;

    uint256 public initialTotalSupply = 100000000 * 1e18;
    uint256 public maxTransactionAmount = 1000000 * 1e18;
    uint256 public maxWallet = 2000000 * 1e18;

    bool public tradingOpen = false;

    mapping(address => bool) private _isExcludedMaxTransactionAmount;

    constructor() ERC20(_name, _symbol) {
        deployerWallet = payable(_msgSender());

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);  
       
        _mint(msg.sender, initialTotalSupply);
    }

    receive() external payable {}

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"Trading is already open");        
        tradingOpen = true;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function removeBots(address[] memory notbot) public onlyOwner {
        for (uint256 i = 0; i < notbot.length; i++) {
            bots[notbot[i]] = false;
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead)) {

            require(!bots[from] && !bots[to]);

            require(tradingOpen, "Trading is not active.");

            if (!_isExcludedMaxTransactionAmount[to]) {
                require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
            }

            else if (!_isExcludedMaxTransactionAmount[from]) {
                require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
            } 
            
            else if (!_isExcludedMaxTransactionAmount[to]) {
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
            }
        }

        super._transfer(from, to, amount);
    }

    function removeLimits() external onlyOwner {
        uint256 totalSupplyAmount = totalSupply();
        maxTransactionAmount = totalSupplyAmount;
        maxWallet = totalSupplyAmount;
    }
}