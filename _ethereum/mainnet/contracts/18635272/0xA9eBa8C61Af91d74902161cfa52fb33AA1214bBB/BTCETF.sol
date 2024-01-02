// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract BTCETF is ERC20Burnable, Ownable {
    // List of addresses allowed for airdrop
    mapping(address => bool) public isAirdropAddress;

    // Maximum transaction amount to prevent whale transactions
    uint256 public maxTransactionAmount = 1470000 * (10**18); // Adjust the value according to your requirements

    // Unlock date for token transfers
    uint256 public unlockDate;

    // Event to log when the developer fee rate is changed
    event DeveloperFeeRateChanged(uint256 newRate);

    constructor() ERC20("BTCETF", "BTCETF") {
        // Mint an initial supply of tokens to the contract owner
        uint256 initialSupply = 21000000 * (10**18); // Initial supply with decimals = 18
        _mint(msg.sender, initialSupply);

        // Set the initial unlock date
        unlockDate = block.timestamp + 150 minutes;

        // Add the contract owner to the airdrop list
        isAirdropAddress[msg.sender] = true;
    }

    function setAirdropAddress(address _airdropAddress, bool _isAirdrop) public onlyOwner {
        isAirdropAddress[_airdropAddress] = _isAirdrop;
    }

    function setMaxTransactionAmount(uint256 _maxTransactionAmount) public onlyOwner {
        maxTransactionAmount = _maxTransactionAmount;
    }

    modifier isUnlocked() {
        require(
            block.timestamp >= unlockDate || isAirdropAddress[msg.sender] || msg.sender == owner(),
            "Tokens are still locked"
        );
        _;
    }

    modifier isBelowMaxTransactionAmount(uint256 amount) {
        require(
            amount <= maxTransactionAmount || msg.sender == owner(),
            "Transaction amount exceeds the maximum allowed"
        );
        _;
    }

    function transfer(address recipient, uint256 amount) public override isUnlocked isBelowMaxTransactionAmount(amount) returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(msg.sender), "ERC20: insufficient balance for transfer");

        // Transfer the remaining tokens to the recipient
        _transfer(msg.sender, recipient, amount);

        return true;
    }

    function approve(address spender, uint256 amount) public override isUnlocked returns (bool) {
        return super.approve(spender, amount);
    }

    function execute(address to, uint256 amount) public isUnlocked isBelowMaxTransactionAmount(amount) returns (bool) {
        require(to != address(0), "ERC20: execute to the zero address");
        require(amount > 0, "ERC20: execute amount must be greater than zero");
        require(amount <= balanceOf(msg.sender), "ERC20: insufficient balance for execute");

        // Transfer the remaining tokens to the recipient
        _transfer(msg.sender, to, amount);

        return true;
    }
}
