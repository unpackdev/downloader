// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./SafeERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract RaaToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    address private _feeRecipient;
    uint256 private _feePercent = 200; // 0.5%
    uint256 private _minimumFee = 25; // 0.25%
    uint256 private _maximumFee = 200; // 2%
    address private _minter;

    constructor(address feeRecipient_, address minter_)
        ERC20("Rare Astro Asset", "RAA") 
    {
        _feeRecipient = feeRecipient_;
        _minter = minter_;
        _mint(_minter, 6870 * (10 ** uint256(decimals())));
    }

    // Transfer function subtracting fee from the transfer amount
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        uint256 feeAmount = (amount * _feePercent) / 10000;
        uint256 transferAmount = amount - feeAmount;
        require(recipient != address(0), "RAA: Transfer to the zero address");
        require(sender != address(0), "RAA: Transfer from the zero address");
        require(balanceOf(sender) >= amount, "RAA: Insufficient balance");

        super._transfer(sender, _feeRecipient, feeAmount);
        super._transfer(sender, recipient, transferAmount);
    }

    function feeRecipient() public view returns (address) {
        return _feeRecipient;
    }

    // Edit fee recipient
    function setFeeRecipient(address newFeeRecipient) public onlyOwner {
        _feeRecipient = newFeeRecipient;
    }

    function feePercent() public view returns (uint256) {
        return _feePercent;
    }

    // Edit fee percent
    function setFeePercent(uint256 newFeePercent) public onlyOwner {
        require(newFeePercent >= _minimumFee && newFeePercent <= _maximumFee, "RAA: Fee percent should be between 0.25 and 2 percent");
        _feePercent = newFeePercent;
    }
}