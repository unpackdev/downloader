// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Ufpe is ERC20, ERC20Burnable, Ownable {
    uint256 private tax;
    address private marketingWallet = address(0);
    uint256 private startTradeBlock = 0;
    bool private stratTrade;
    string public constant _name = 'Ufpe';
    string public constant _symbol = 'Ufpe';

    uint256 private constant TOTAL_SUPPLY = 1000 * 10 ** 18;

    mapping(address => bool) private _botlist;

    constructor() ERC20(_name, _symbol) {
        tax = 20; 
        stratTrade = false;
        marketingWallet = _msgSender();
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function start(bool bStart) external onlyOwner {
        stratTrade = bStart;
        if(startTradeBlock == 0){
            startTradeBlock = block.number;
        }
    }
    
    // set the tax rate
    function setRate(uint256 newTaxRate) external onlyOwner {
        require(newTaxRate <= 30, "Tax rate must be less than or equal to 30");
        tax = newTaxRate;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(marketingWallet != address(0));
        require(!_botlist[sender], "Sender is botlisted");
        require(!_botlist[recipient], "Recipient is botlisted");
        
        if (sender != owner() && recipient != owner()) {
            require(stratTrade, "not start");

            if (block.number < startTradeBlock + 3) {
                _botlist[recipient] = true;
            }

            uint256 taxAmount = (amount * tax) / 100;
            uint256 transferAmount = amount - taxAmount;

            super._transfer(sender, recipient, transferAmount);
            super._transfer(sender, marketingWallet, taxAmount); 
        } else {
            super._transfer(sender, recipient, amount);
        }
    }
}