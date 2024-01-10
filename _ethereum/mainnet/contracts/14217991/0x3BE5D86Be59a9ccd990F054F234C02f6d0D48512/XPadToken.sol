// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "Ownable.sol";
import "Address.sol";
import "draft-ERC20Permit.sol";


contract XPadToken is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    using Address for address payable;

    uint256 MAX_TAX = 500;
    // address / contract receiving the tax
    address public taxRecipient;

    mapping (address => bool) public taxExcluded;
    // tax fee, 2 decimal points, so "253" is "2.53%"
    uint256 public taxFee;

    event TaxChanged(uint256 taxFee);
    event TaxRecipientChanged(address newRecipient);

    constructor(address _taxRecipient) ERC20("xPAD", "XPAD") ERC20Permit("XPad") {
        setTaxFee(200);  // 2%
        excludeFromTax(_msgSender());
        excludeFromTax(address(this));
        _mint(msg.sender, 25_000_000 * 10 ** decimals());
        setTaxRecipient(_taxRecipient);
    }

    function setTaxRecipient(address _taxRecipient) onlyOwner public {
        require(_taxRecipient != address(0), "Tax recipient can't be null address");
        require(_taxRecipient != address(this), "Tax recipient can't be contract itself");
        excludeFromTax(_taxRecipient);
        taxRecipient = _taxRecipient;
        emit TaxRecipientChanged(_taxRecipient);
    }

    function setTaxFee(uint256 _taxFee) public onlyOwner {
        require(_taxFee <= MAX_TAX, "Requested tax is too high");
        taxFee = _taxFee;
        emit TaxChanged(_taxFee);
    }

    // excluding from tax is needed because of some contracts
    // like contract for converting SB into XPad - these should
    // not be taxed.
    function excludeFromTax(address who) public onlyOwner {
        taxExcluded[who] = true;
    }

    function includeInTax(address who) external onlyOwner {
        taxExcluded[who] = false;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        bool collectTax = (!(taxExcluded[from] || taxExcluded[to])) && taxFee > 0;

        // no tax, do things as always
        if(!collectTax) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 taxAmount = (amount * taxFee) / (100 * 100);
        uint256 restAmount = amount - taxAmount;

        super._transfer(from, taxRecipient, taxAmount);
        super._transfer(from, to, restAmount);
    }
}