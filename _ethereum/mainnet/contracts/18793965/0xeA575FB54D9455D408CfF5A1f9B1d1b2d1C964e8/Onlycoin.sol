// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";

contract Onlycoin is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public constant TOTAL_SUPPLY = 21_000_000 ether; 
    uint8 public constant MAX_TAX_RATE = 100;
    uint16 public taxRate;
    address public taxWallet;
    address public pair;

    mapping(address => bool) public taxExemptList;

    event SetTaxRate(uint8 newTaxRate);
    event SetTaxWallet(address newTaxAddress);
    event IncludeToTaxExemptList(address wallet);
    event ExcludeFromTaxExemptList(address wallet);
    event Withdraw(address recipient, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        uint8 _taxRate,
        address _taxWallet,
        address factory,
        address weth
    ) ERC20(name, symbol) {
        require(_taxRate <= MAX_TAX_RATE, "Tax rate exceeds maximum");
        _mint(msg.sender, TOTAL_SUPPLY);

        taxRate = _taxRate;
        taxWallet = _taxWallet;

        pair = IUniswapV2Factory(factory).createPair(address(this), address(weth));
    }

    function setTaxRate(uint8 _newTaxRate) external onlyOwner {
        require(_newTaxRate <= MAX_TAX_RATE, "New tax rate exceeds maximum");
        taxRate = _newTaxRate;
        emit SetTaxRate(_newTaxRate);
    }

    function setTaxWallet(address _newTaxWallet) external onlyOwner {
        taxWallet = _newTaxWallet;
        emit SetTaxWallet(_newTaxWallet);
    }

    function includeToTaxExemptList(address wallet) external onlyOwner {
        require(!taxExemptList[wallet], "Already in the tax exempt list");
        taxExemptList[wallet] = true;
        emit IncludeToTaxExemptList(wallet);
    }

    function excludeFromTaxExemptList(address wallet) external onlyOwner {
        require(taxExemptList[wallet], "Not in the tax exempt list");
        taxExemptList[wallet] = false;
        emit ExcludeFromTaxExemptList(wallet);
    }

    function withdraw(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient balance for withdrawal");

        recipient.transfer(amount);

        emit Withdraw(recipient, amount);
    }

    receive() external payable {}

    function _isSwap(address sender_, address recipient_) internal view returns (bool isSwap) {
        if (sender_ == pair || recipient_ == pair) {
            return true;
        } else {
            return false;
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
       
        address contractOwner = owner();
        if (
            _isSwap(sender, recipient) &&
            sender != contractOwner &&
            sender != taxWallet &&
            recipient != contractOwner &&
            recipient != taxWallet &&
            taxRate != 0 &&
            !taxExemptList[sender] &&
            !taxExemptList[recipient]
        ) {
            uint256 taxAmount = amount.mul(taxRate).div(MAX_TAX_RATE);
            uint256 afterTaxAmount = amount.sub(taxAmount);
            super._transfer(sender, taxWallet, taxAmount);
            super._transfer(sender, recipient, afterTaxAmount);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }
}
