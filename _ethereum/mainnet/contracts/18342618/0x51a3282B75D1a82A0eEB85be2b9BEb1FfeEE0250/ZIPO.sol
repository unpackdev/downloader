// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract ZIPO is ERC20Burnable, Ownable {
    uint256 private constant BURN_RATE = 42; // 0.42% burning rate
    uint256 private devFeeRate = 369; // 0.369% developer fee rate

    address public devFeeWallet; // Address where developer fees are sent

    uint256 public unlockDate; // Timestamp when tokens become tradable
    uint256 public lockDuration; // Duration in seconds for the lock timer

    bool public lockTimerEnabled = true; // New state variable to enable/disable lock timer

    // List of airdrop contracts allowed to transfer tokens before unlockDate
    mapping(address => bool) public isAirdropContract;

    // Event to log when the developer fee rate is changed
    event DeveloperFeeRateChanged(uint256 newRate);
    event LockTimerEnabled(bool enabled); // New event to log lock timer state change

    constructor() ERC20("zipo", "ZIPO") {
        // Mint an initial supply of tokens to the contract owner
        uint256 initialSupply = 69420000000 * (10**18); // Initial supply with decimals = 18
        _mint(msg.sender, initialSupply);

        // Set the developer fee wallet address to the contract owner
        devFeeWallet = msg.sender;

        // Set the initial unlock date and lock duration (30 minutes by default)
        unlockDate = block.timestamp + 10080 minutes;
        
    }

    function setDevFeeWallet(address _devFeeWallet) public onlyOwner {
        devFeeWallet = _devFeeWallet;
    }

    // Function to set the developer fee rate, only callable by the owner
    function setDeveloperFeeRate(uint256 _newRate) public onlyOwner {
        devFeeRate = _newRate;
        emit DeveloperFeeRateChanged(_newRate);
    }

    // Function to add or remove an airdrop contract
    function setAirdropContract(address _airdropContract, bool _isAirdrop) public onlyOwner {
        isAirdropContract[_airdropContract] = _isAirdrop;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(block.timestamp >= unlockDate || msg.sender == owner() || isAirdropContract[msg.sender], "Tokens are still locked");

        uint256 burnAmount = (amount * BURN_RATE) / 10000; // Calculate the burn amount
        uint256 devFeeAmount = (amount * devFeeRate) / 100000; // Calculate the developer fee amount (0.369%)
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
}
