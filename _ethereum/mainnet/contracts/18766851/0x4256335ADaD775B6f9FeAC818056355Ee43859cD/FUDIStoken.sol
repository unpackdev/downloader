// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

/**
 * FUDIS TOKEN Business Model Strategy
 *
 * ███████  ██    ██   ████████   ██████  ██████
 * ██       ██    ██   ██    ██     ██    ██    
 * █████    ██    ██   ██    ██     ██    ██████  
 * ██       ██    ██   ██    ██     ██        ██
 * ██       ████████   ████████   ██████  ██████
 * 
 *
 * National Enquirer's Buzzworthy Approach: Fudis will leverage the engaging and attention-grabbing style
 * of the National Enquirer to create buzz around the crypto world. Our platform will feature captivating
 * content, keeping our audience hooked and excited.
 *
 * Craigslist's User-Centric Marketplace: Inspired by Craigslist's simplicity and effectiveness, Fudis will
 * offer a user-centric marketplace. Our platform will provide a seamless experience for users to buy, sell,
 * and trade crypto assets while fostering a vibrant community.
 *
 * New York Times' Credible Reporting: Following the footsteps of The New York Times, Fudis aims to deliver
 * credible and informative content. We'll provide users with reliable news and insights, becoming a trusted
 * source in the crypto space.
 *
 * YouTube's Content Monetization: Taking a page from YouTube's book, Fudis will explore content
 * monetization. Our platform will reward content creators and users for their engagement, creating a dynamic
 * ecosystem where everyone benefits.
 *
 * Innovative Ad Models and Beyond: Fudis Token will introduce innovative advertising models, inspired by
 * successful platforms. From strategic partnerships and sponsored content to targeted advertising, we'll
 * implement diverse ad models that cater to the crypto community's interests.
 *
 * Dynamic Subscription Models: Inspired by subscription-based models like The New York Times, Fudis will
 * explore dynamic subscription plans. Users can access premium content, exclusive features, and benefits
 * through subscription tiers, enhancing their overall experience.
 *
 * By combining the best elements from these proven business models, Fudis Token aims to create a
 * multifaceted platform that not only survives but thrives in the competitive crypto landscape. Get ready
 * for a revolutionary blend of tradition and innovation!
 *
 * Embark on this exciting business journey with us by dropping a message! Whether you've got a brilliant
 * idea, want to support FUDIS Token, contribute to our weekly giveaway with an article, or simply fancy a
 * chat, we're all ears and eagerly await your insights! 🚀🗣️
 *
 * Sponsors, project owners, YouTubers, or other businesses looking to collaborate can also reach out here.
 * Let's connect and explore the endless possibilities together!
 */
contract FudisToken is ERC20, ERC20Burnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Addresses
    address public liquidityAddress;
    address public liquidityTaxWallet;
    address public deployerWallet = 0x86D6A26e35266AC9eD4A8452353787cF1C00cC40;  // Updated deployer wallet
    address private _owner;

    // Sell tax rate and whitelist
    uint256 public sellTaxRate;
    mapping(address => bool) public whitelist;

    // Modifiers
    modifier onlyOwner() {
        require(owner() == msg.sender, "Not owner");
        _;
    }

    // Constructor
    constructor() ERC20("F-U-Dis Token Times", "FUDIS") {
        _mint(deployerWallet, 1_000_000_000 ether);
        sellTaxRate = 0;  // Initial tax rate set to zero
        _owner = deployerWallet;
    }

    // Get owner address
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Set liquidity address.
     * @param _liquidityAddress The new liquidity address.
     */
    function setLiquidityAddress(address _liquidityAddress) external onlyOwner {
        require(_liquidityAddress != address(0), "Invalid address");
        liquidityAddress = _liquidityAddress;
    }

    /**
     * @dev Set liquidity tax wallet.
     * @param _liquidityTaxWallet The new liquidity tax wallet address.
     */
    function setLiquidityTaxWallet(address _liquidityTaxWallet) external onlyOwner {
        require(_liquidityTaxWallet != address(0), "Invalid address");
        liquidityTaxWallet = _liquidityTaxWallet;
    }

    /**
     * @dev Set sell tax rate.
     * @param _sellTaxRate The new sell tax rate.
     */
    function setSellTaxRate(uint256 _sellTaxRate) external onlyOwner {
        require(_sellTaxRate <= 100, "Invalid rate");
        sellTaxRate = _sellTaxRate;
    }

    /**
     * @dev Sell tokens.
     * @param amount The amount of tokens to sell.
     */
    function sell(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        uint256 taxAmount = amount.mul(sellTaxRate).div(100);
        uint256 transferAmount = amount.sub(taxAmount);

        require(transferAmount > 0, "Invalid transfer amount");

        _transfer(msg.sender, liquidityAddress, transferAmount);
        _burn(msg.sender, taxAmount);
    }

    /**
     * @dev Add address to whitelist.
     * @param account The address to add to the whitelist.
     */
    function addToWhitelist(address account) external onlyOwner {
        whitelist[account] = true;
    }

    /**
     * @dev Remove address from whitelist.
     * @param account The address to remove from the whitelist.
     */
    function removeFromWhitelist(address account) external onlyOwner {
        whitelist[account] = false;
    }

    /**
     * @dev Renounce contract ownership.
     */
    function renounceContract() external onlyOwner {
        require(msg.sender == deployerWallet, "Not deployer");
        _owner = address(0);
    }
}
