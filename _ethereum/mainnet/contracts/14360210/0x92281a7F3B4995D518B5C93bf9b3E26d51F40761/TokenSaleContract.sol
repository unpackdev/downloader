// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";
import "./GPO.sol";
import "./NonReentrancy.sol";
import "./Ownable.sol";

contract TokenSaleContract is ReentrancyGuard, Ownable {

    // Chainlink Aggregator used to retrieve the live Ethereum price
    AggregatorV3Interface internal priceFeed;
    // Name of the Token Sale
    string public saleName;
    // Start time of the Token Sale (Unix Time)
    uint256 public startUnixTime;
    // Total Amount of Tokens for Sale
    uint256 public saleAmount;
    // Total Sale Amount 
    uint256 public amountSold;
    // GPO Contract 
    GPO public gpo;
    // Wallet address where sale funds are transferred to
    address payable private fundWallet;
    // Price per token in USD Cents
    uint256 public priceInUSDCents;
    // State of the Sale 
    bool public saleEnded;
    // Event is emitted anytime tokens are purchased
    event TokensPurchased(
        address indexed purchaser,
        uint256 value,
        uint256 amount,
        uint256 timestamp
    );
    // Sale has started and has not ended
    modifier duringSale() {
        require(block.timestamp >= startUnixTime && !saleEnded, "Not during sale");
        _;
    }
    // Sale has ended
    modifier afterSale() {
        require(saleEnded);
        _;
    }
    // Sale has not started
    modifier beforeSale() {
        require(block.timestamp <= startUnixTime);
        _;
    }
    // Constructor is only executed once when the contract is deployed and initalizes the state variables for the specific sale
    constructor(
        string memory _saleName,
        uint256 _startUnixTime,
        uint256 _saleAmount,
        address _gpo,
        address payable _fundWallet,
        uint256 _priceInUSDCents,
        address _ethUsdAggregator
    ) {
        saleName = _saleName;
        startUnixTime = _startUnixTime;
        saleAmount = _saleAmount * 10**18;
        gpo = GPO(_gpo);
        priceInUSDCents = _priceInUSDCents;
        priceFeed = AggregatorV3Interface(_ethUsdAggregator);
        amountSold = 0;
        fundWallet = _fundWallet;
        saleEnded = false;
    }
    // fetches the price of each token in Ethereum at the moment of the purchase
    function getSalePriceInETH() public view returns (uint256) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        return (priceInUSDCents * 10**24) / uint256(price);
    }
    // Amount of GPO per Ethereum
    function tentativeAmountGPOPerETH(uint256 amount) public view returns (uint256) {
        return (amount * 10**18) / getSalePriceInETH();
    }
    // Executes the buy order as long as there are enough tokens left for sale and the user requesting to purchase tokens will not breach the wallet hard cap of 100,000
    // Once the tokens are successful purchased and transferred to the user, their wallet is locked. 
    function buyTokens() public payable nonReentrant duringSale {
        require(_msgSender() != address(0), "No address 0");
        require(msg.value > 0, "Msg value = 0");

        uint256 tentativeAmountGPO = tentativeAmountGPOPerETH(msg.value);

        require(gpo.balanceOf(address(this)) >= tentativeAmountGPO, "Do not have enough GPO");
        require(gpo.balanceOf(_msgSender()) + tentativeAmountGPO <= gpo.hardCapOnWallet(), "Limit reached");

        gpo.transfer(_msgSender(), tentativeAmountGPO);
        gpo.lockUnlockWallet(_msgSender(), true, tentativeAmountGPO);
        amountSold = amountSold + tentativeAmountGPO;

        emit TokensPurchased(_msgSender(), msg.value, tentativeAmountGPO, block.timestamp);

        transferFunds();
    }

    // After the Sale is finished the remaining GPO tokens are transferred back to the GPO contract address
    function transferRemainingTokens() public afterSale onlyOwner {
        require(amountSold != saleAmount);

        gpo.transfer(address(gpo), gpo.balanceOf(address(this)));
    }
    // Sets the wallet address that recieves the sale proceeds of the token sale
    function setFundWallet(address payable _fundWallet) public onlyOwner {
        fundWallet = _fundWallet;
    }
    // Transfer the sale proceeds to the "FundWallet"
    function transferFunds() internal {
        fundWallet.transfer(address(this).balance);
    }
    // Enables GoldPesa to end the sale early
    function endSale() public duringSale onlyOwner {
        saleEnded = true;
    }
    
}
