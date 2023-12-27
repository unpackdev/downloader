// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract TaxableTeamToken is ERC20, Ownable {
    using SafeMath for uint256;
    uint256 private _upperLimmitOfTaxPercentage = 1000;
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public restrictedUser;
    address public feeWallet;
    uint256 public tax;

    constructor(
        uint256 supply,
        uint256 _tax,
        address owner,
        address _feeWallet
    ) ERC20("BossMoves", "BSMV") {
        require(
            supply > 0,
            "[Validation] inital supply should be greater than 0"
        );
        require(
            owner != feeWallet,
            "[Validation] fee wallet and owner wallet cannot be same."
        );
        require(
            _feeWallet != address(0),
            "Fees address can not be zero address"
        );
        owner = owner;
        tax = _tax;
        feeWallet = _feeWallet;
        isExcludedFromFee[feeWallet]=true;
        isExcludedFromFee[owner] = true;
        isExcludedFromFee[address(this)] = true;
        _mint(owner, supply * 10 ** decimals());
    }

    function percent(
        uint256 amount,
        uint256 fraction
    ) public pure virtual returns (uint256) {
        return ((amount).mul(fraction)).div(10000);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function setFeeWallet(address _feeWallet) public onlyOwner {
        require(
            _feeWallet != address(0),
            "Fees address can not be zero address"
        );
        isExcludedFromFee[feeWallet]=true;
        feeWallet = _feeWallet;
    }
 
    function setTax(uint256 percentage) public onlyOwner {
        require(
            _upperLimmitOfTaxPercentage >= percentage,
            "Limit exceed(can not set more than 10 percent)"
        );
        tax = percentage;
    }
    
    function excludeFromFee(address[] calldata account) public onlyOwner {
        for (uint256 i = 0; i < account.length; i++) {
            isExcludedFromFee[account[i]] = true;
        }
    }

    function includeInFee(address[] calldata account) public onlyOwner {
        for (uint256 i = 0; i < account.length; i++) {
            isExcludedFromFee[account[i]] = false;
        }
    }

    function restrictUser(address[] calldata account) public onlyOwner {
        for (uint256 i = 0; i < account.length; i++) {
            restrictedUser[account[i]] = true;
        }
    }

    function removeFromRestrictedUser(
        address[] calldata account
    ) public onlyOwner {
        for (uint256 i = 0; i < account.length; i++) {
            restrictedUser[account[i]] = false;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = balanceOf(from);
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        require(
            !(restrictedUser[from] || restrictedUser[to]),
            "account is restricted for transfer"
        );
        if (isExcludedFromFee[from] || from==owner()) {
            super._transfer(from, to, amount);
        } else {
            uint256 taxAmount = percent(amount, tax);
            super._transfer(from, feeWallet, taxAmount);
            super._transfer(from, to, amount - taxAmount);
        }
    }
}
