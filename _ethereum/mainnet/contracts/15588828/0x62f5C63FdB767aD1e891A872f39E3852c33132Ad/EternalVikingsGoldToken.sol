// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC20.sol";
import "./Ownable.sol";

contract EternalVikingsGoldToken is ERC20, Ownable {
    address public EVYielder;
    address public EVConsumer;
    address public EVTaxReceiver;

    mapping(address => bool) public dexPair;
    bool public isAddLpPeriod;

    bool public buyTaxActive;
    uint256 public buyTaxAmount;
    uint256 public buyTaxDenomination;

    bool public sellTaxActive;
    uint256 public sellTaxAmount;
    uint256 public sellTaxDenomination;

    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) Ownable() {
        buyTaxDenomination = 100;
        sellTaxDenomination = 100;
    }

    receive() external payable {
        payable(owner()).transfer(address(this).balance);
    }

    function reward(address to, uint256 amount) external {
        require(msg.sender == EVYielder, "Unauthorized: Yielder");
        require(EVYielder != address(0), "Null: Yielder");
        _mint(to, amount);
    }

    function consume(address from, uint256 amount) external {
        require(msg.sender == EVConsumer, "Unauthorized: Consumer");
        require(EVConsumer != address(0), "Null: Consumer");
        _burn(from, amount);
    }

    function setYielder(address _yielder) external onlyOwner {
        EVYielder = _yielder;
    }

    function setConsumer(address _consumer) external onlyOwner {
        EVConsumer = _consumer;
    }

    function setEVTaxReceiver(address _receiver) external onlyOwner {
        EVTaxReceiver = _receiver;
    }

    function setDexPair(address pair, bool isPair) external onlyOwner {
        dexPair[pair] = isPair;
    }

    function setIsAddLpPeriod(bool isLpPeriod) external onlyOwner {
        isAddLpPeriod = isLpPeriod;
    }

    function setBuyTaxActive(bool active) external onlyOwner {
        buyTaxActive = active;
    }

    function setBuyTaxAmount(uint256 amount) external onlyOwner {
        buyTaxAmount = amount;
    }

    function setBuyTaxDenomination(uint256 denom) external onlyOwner {
        buyTaxDenomination = denom;
    }

    function setSellTaxActive(bool active) external onlyOwner {
        sellTaxActive = active;
    }

    function setSellTaxAmount(uint256 amount) external onlyOwner {
        sellTaxAmount = amount;
    }

    function setSellTaxDenomination(uint256 denom) external onlyOwner {
        sellTaxDenomination = denom;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (isAddLpPeriod) {
            if (dexPair[from]) {
                revert();
            }
        }

        uint256 transferAmountAfterTax = amount;
        if (
            dexPair[to] &&             
            sellTaxActive &&
            sellTaxAmount > 0 && 
            sellTaxAmount < 100) {
                uint256 taxDeduction = amount * sellTaxAmount / sellTaxDenomination;
                transferAmountAfterTax = amount - taxDeduction;
                super._transfer(from, EVTaxReceiver, taxDeduction);
        } else if (
            dexPair[from] &&             
            buyTaxActive &&
            buyTaxAmount > 0 && 
            buyTaxAmount < 100) {
                uint256 taxDeduction = amount * buyTaxAmount / buyTaxDenomination;
                transferAmountAfterTax = amount - taxDeduction;
                super._transfer(from, EVTaxReceiver, taxDeduction);
        }
        
        super._transfer(from, to, transferAmountAfterTax);
    }
}