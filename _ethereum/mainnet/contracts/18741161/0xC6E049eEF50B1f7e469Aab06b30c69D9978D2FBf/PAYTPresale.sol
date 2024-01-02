// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/// @title PAYT Token Presale Contract
/// @notice This contract manages the presale of PAYT tokens
contract PAYTPresale is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public rate;
    uint256 public round;
    uint256 public weiRaised;
    uint256 public totalTokensSold;
    uint256 public totalTokensClaimed;
    uint256 public minPurchaseAmount;
    bool public isPresaleActive = false;
    bool public isPresaleEnded = false;

    modifier whenPresaleActive() { 
        require(isPresaleActive, "TokenPresale: Presale is not active"); 
        _; 
    }

    mapping(address => uint256) public contributions;
    mapping(address => uint256) public tokensBought;

    event TokenPurchasedWithEther(address indexed purchaser, uint256 value, uint256 amount);
    
    /// @notice Constructor to set initial values
    /// @param initialOwner The initial owner of the contract
    /// @param _token The token being sold
    /// @param _rate The rate of token per Ether
    constructor(address initialOwner, address _token, uint256 _rate) Ownable(initialOwner) {
        require(_rate > 0 && _rate < 50000 && address(_token) != address(0) , "TokenPresale: Invalid parameters");
        token = IERC20(_token); 
        rate = _rate;
        minPurchaseAmount = 0.01 ether;
    }

    receive() external payable { 
        buy(); 
    }

    function getCurrentRate() public view returns (uint256) { return rate; }
    function getTotalTokensSold() public view returns (uint256) { return totalTokensSold; }
    function getTokensAvailable() public view returns (uint256) { return token.balanceOf(address(this)); }
    function setRate(uint256 _rate) external onlyOwner { require(_rate > 0 && _rate < 50000, "TokenPresale: Invalid rate"); rate = _rate; }
    function startPresale() external onlyOwner { isPresaleActive = true; }
    function stopPresale() external onlyOwner { isPresaleActive = false; }
    function endPresale() external onlyOwner { isPresaleActive = false; isPresaleEnded = true; }

    function getClaimedAmount(address beneficiary) public view returns (uint256) {
        return tokensBought[beneficiary];
    }

    /// @notice Allows users to buy tokens with ETH
    function buy() public nonReentrant payable whenPresaleActive {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(msg.sender, weiAmount);
        uint256 tokens = _getTokenAmountForEther(weiAmount);

        contributions[msg.sender] += weiAmount;
        tokensBought[msg.sender] += tokens;
        weiRaised += weiAmount;
        totalTokensSold += tokens;

        emit TokenPurchasedWithEther(msg.sender, weiAmount, tokens);
    }
    
    /// @notice Allows users to claim tokens
    function claim() external nonReentrant {
        require(isPresaleEnded, "TokenPresale: Presale is not ended yet!");

        // Doublecheck if the beneficiary did contribute
        uint256 amountContributed = contributions[msg.sender];
        require(amountContributed > 0, "TokenPresale: No contributions found");

        // Calculate the amount of tokens in the different rounds and ensure that the tokens are available to claim
        uint256 tokensToClaim = tokensBought[msg.sender];
        require(tokensToClaim <= token.balanceOf(address(this)), "TokenPresale: Insufficient tokens");

        // Reset contribution to prevent double claiming
        contributions[msg.sender] = 0;
        totalTokensClaimed += tokensToClaim;
        tokensBought[msg.sender] = 0;

        // Transfer tokens to the beneficiary
        token.safeTransfer(msg.sender, tokensToClaim);
    }

    function claimERC20(IERC20 _token) external onlyOwner {
        uint256 contractTokenBalance = _token.balanceOf(address(this));
        uint256 unsoldTokens = contractTokenBalance - totalTokensSold; // Need to put the amount which is left to claim.
        require(unsoldTokens > 0, "TokenPresale: No ERC20 tokens to withdraw");
        _token.safeTransfer(owner(), unsoldTokens);
    }

    function claimETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "TokenPresale: No ETH to withdraw");
        address payable to = payable(owner());
        to.transfer(balance);
    }

    function _preValidatePurchase(address beneficiary, uint256 amount) internal view { 
        require(beneficiary != address(0) && amount != 0, "TokenPresale: Invalid purchase parameters"); 
        require(amount >= minPurchaseAmount, "TokenPresale: Amount is less than the minimum purchase amount");
    }

    function _getTokenAmountForEther(uint256 weiAmount) private view returns (uint256) { return weiAmount * rate; }
}
