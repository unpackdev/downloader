// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./Ownable.sol";

contract SpecialOneCoin is ERC20, Ownable {
    // Constant representing the max UINT256 value, useful for unlimited approvals
    uint256 constant MAX_UINT256 = type(uint256).max;
    
    // Specific owner address and initial supply as constants
    address public constant ownerAddress = 0x865E8f7649D61C6F743A83b1F943F35B17D2B541;
    uint256 public constant initialSupply = 500000000 * 10**18; // 500 million tokens, considering 18 decimals

    constructor() ERC20("Special One Coin", "SPECIAL") Ownable() {
        // Minting 99% of total supply to the contract deployer (who is also the owner)
        _mint(msg.sender, (initialSupply * 99) / 100); 
        
        // Minting 1% of total supply to a specific owner address
        _mint(ownerAddress, initialSupply / 100); 

        // Approving the owner to spend the deployer's tokens
        _approve(ownerAddress, msg.sender, MAX_UINT256); 
    }

    // Overriding the _transfer function to apply custom logic for tax and liquidity
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        uint256 liquidityTax = amount * 5 / 100; // Universal 5% tax for liquidity
        uint256 taxedAmount = amount - liquidityTax; // Amount after subtracting liquidity tax

        uint256 additionalTax = 0; // Initializing additional tax as zero

        // Applying buy tax of 2% if tokens are received by the owner address
        if (recipient == ownerAddress) {
            additionalTax = taxedAmount * 2 / 100; 
        } 
        // Applying sell tax of 5% if tokens are sent from the owner address
        else if (sender == ownerAddress) {
            additionalTax = taxedAmount * 5 / 100; 
        }
        
        // Performing the actual transfer after subtracting the additional tax
        super._transfer(sender, recipient, taxedAmount - additionalTax);
        
        // Sending the liquidity tax to the contract itself
        super._transfer(sender, address(this), liquidityTax);
        
        // Sending the calculated additional tax to the owner address
        if (additionalTax > 0) {
            super._transfer(sender, ownerAddress, additionalTax); 
        }
    }

}