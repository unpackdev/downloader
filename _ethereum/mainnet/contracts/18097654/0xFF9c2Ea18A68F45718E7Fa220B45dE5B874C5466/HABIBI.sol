// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract HABIBI is ERC20Burnable, Ownable {
    uint256 private constant BURN_RATE = 42; // 0.42% burning rate
    uint256 private constant DEV_FEE_RATE = 369; // 0.369% developer fee rate

    address public devFeeWallet; // Address where developer fees are sent

    constructor() ERC20("HABIBI", "HABIBI") {
        // Mint an initial supply of tokens to the contract owner
        uint256 initialSupply = 100000000000 * 10 ** decimals(); // 1,000,000 tokens with decimals = 18
        _mint(msg.sender, initialSupply);

        // Set the developer fee wallet address to the contract owner
        devFeeWallet = msg.sender;
    }

    function setDevFeeWallet(address _devFeeWallet) public onlyOwner {
        devFeeWallet = _devFeeWallet;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        _mint(account, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 burnAmount = (amount * BURN_RATE) / 10000; // Calculate the burn amount
        uint256 devFeeAmount = (amount * DEV_FEE_RATE) / 100000; // Calculate the developer fee amount (0.369%)
        uint256 transferAmount = amount - burnAmount - devFeeAmount; // Calculate the transfer amount after fees

        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(burnAmount <= balanceOf(msg.sender), "ERC20: burn amount exceeds balance");

        // Burn tokens
        _burn(msg.sender, burnAmount);

        // Transfer remaining tokens to the recipient
        _transfer(msg.sender, recipient, transferAmount);

        // Send developer fee to the devFeeWallet
        _transfer(msg.sender, devFeeWallet, devFeeAmount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 burnAmount = (amount * BURN_RATE) / 10000; // Calculate the burn amount
        uint256 devFeeAmount = (amount * DEV_FEE_RATE) / 100000; // Calculate the developer fee amount (0.369%)
        uint256 transferAmount = amount - burnAmount - devFeeAmount; // Calculate the transfer amount after fees

        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(burnAmount <= balanceOf(sender), "ERC20: burn amount exceeds balance");

        // Burn tokens
        _burn(sender, burnAmount);

        // Transfer remaining tokens to the recipient
        _transfer(sender, recipient, transferAmount);

        // Send developer fee to the devFeeWallet
        _transfer(sender, devFeeWallet, devFeeAmount);

        uint256 currentAllowance = allowance(sender, msg.sender);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }
}
