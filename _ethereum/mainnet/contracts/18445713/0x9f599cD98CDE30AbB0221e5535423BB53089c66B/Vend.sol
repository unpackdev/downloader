pragma solidity ^0.8.20;

import "./IERC20.sol";

contract Vend {

    IERC20 public token;
    address public owner;
    uint256 public tokensSold = 1;
    uint256 public INITIAL_PRICE = 24500000000000;  // Initial price per token in eth wei (26666.6666666667 per eth, 60mm FDV)
    uint256 public PRICE_INCREMENT = 245000000; // Price increment per token in wei

    mapping(address => uint256) public referralAmounts;

    event TokensBought(address indexed buyer, uint256 amount, uint256 totalCost);
    event TokensSold(address indexed seller, uint256 amount, uint256 totalGain);

    event CalculateBuyTokensInputs(uint256 numTokens, uint256 priceForTokens, uint256 allowance, uint256 tokensSold, uint256 msgValue);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function setInitialPrice(uint256 _initialPrice) public onlyOwner {
        INITIAL_PRICE = _initialPrice;
    }

    function setPriceIncrement(uint256 _priceIncrement) public onlyOwner {
        PRICE_INCREMENT = _priceIncrement;
    }

    function setTokensSold(uint256 _tokensSold) public onlyOwner {
        tokensSold = _tokensSold;
    }

    function calculatePrice(uint256 numTokens) public view returns (uint256) {
        return (INITIAL_PRICE + (tokensSold * PRICE_INCREMENT)) * numTokens;
    }

    function calculateTokensExchanged(uint256 ethAmount) public view returns (uint256) {
        uint256 currentPrice = INITIAL_PRICE + (tokensSold * PRICE_INCREMENT);
        uint256 tokensReceived = ethAmount / currentPrice;
        return tokensReceived;
    }

    function buyTokens() public payable {
        buyTokensWithReferrer(address(0));
    }
    
    function buyTokensWithReferrer(address referralId) public payable {
        uint256 numTokens = calculateTokensExchanged(msg.value);
        uint256 priceForTokens = calculatePrice(numTokens);

        uint256 allowance = token.allowance(owner, address(this));
        require(allowance >= numTokens, "Contract not allowed to transfer enough tokens");

        tokensSold = tokensSold + numTokens;

        if (referralId != address(0)) {
            referralAmounts[referralId] += msg.value;
        }

        // Transfer excess funds back to the buyer
        if (msg.value > priceForTokens * numTokens) {
            payable(msg.sender).transfer(msg.value - (priceForTokens * numTokens));
        }

        emit CalculateBuyTokensInputs(numTokens, priceForTokens, allowance, tokensSold, msg.value);

        // Transfer tokens to the buyer
        require(token.transferFrom(owner, msg.sender, numTokens * 10**18), "Token transfer failed");

        emit TokensBought(msg.sender, numTokens, priceForTokens * numTokens);
    }

    function withdrawFunds() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {
        buyTokens();
    }
}

