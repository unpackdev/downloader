// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./Ownable.sol";

contract NGO_COIN is ERC20, Ownable {
    address public feeWallet = 0x6EC09a92fe798765dC1df538434a3a2C97055c62; // Updated fee wallet address
    uint256 public feePercentage;

    constructor(address initialOwner) ERC20("NGO COIN", "NGO") Ownable(initialOwner) {
        _mint(initialOwner, 1310000000 * 10 ** uint256(decimals())); // Initial supply: 1,310,000,000 tokens with 18 decimals
        feePercentage = 1; // 1% fee
    }
    function setFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100%");
        feePercentage = _newFeePercentage;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * feePercentage) / 100;
        uint256 netAmount = amount - fee;

        _transfer(_msgSender(), feeWallet, fee); // Send the fee to the fee wallet
        _transfer(_msgSender(), recipient, netAmount); // Transfer the net amount

        return true;
    }
}
