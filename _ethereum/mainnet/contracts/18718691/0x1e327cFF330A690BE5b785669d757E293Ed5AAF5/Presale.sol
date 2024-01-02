//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./SafeERC20.sol";
import "./Ownable.sol";

interface Aggregator {
   function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract Presale is Ownable{
    using SafeERC20 for IERC20;
	
	uint256 public tokensSold;
    uint256 public USDRaised;
	
	address public paymentWallet;
	address public VENUSPEPE;
	Aggregator public aggregatorInterface;
	
	bool[2] public presaleStatus;
	uint256[2] public tokenToSell;
	uint256[2] public tokenPrice;
	uint256[2] public remainingToSell;
	
	struct buyTokenInfo {
	  uint256 USDPaid;
	  uint256 tokenFromBuy; 
    }
	
	mapping(address => buyTokenInfo) public mapBuyTokenInfo;
	
    event TokensBought(address user, uint256 tokens, uint256 amount, uint256 timestamp);
	event PreSaleStatusUpdated(bool status);
	event RoundPriceUpdated(uint256 round, uint256 price);
	event PaymentWalletUpdated(address wallet);
	event VENUSPEPEUpdated(address contractAddress);
	event MigrateTokens(uint256 amount);
	
    constructor(address payment) {
	   require(address(payment) != address(0), "Zero address");
	   
	   tokenToSell = [500000000 * 10**18, 8250000000 * 10**18];
	   remainingToSell = [500000000 * 10**18, 8250000000 * 10**18];
	   tokenPrice = [1 * 10**2, 1 * 10**3];
	   presaleStatus = [false, false];
	   
	   aggregatorInterface = Aggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
	   paymentWallet = address(payment);
	}
	
	function buyToken(uint256 round) external payable {
	   uint256 amount = (getLatestPrice() * msg.value) / (10**30);
	   require(amount > 0, "Amount must be greater than zero");
	   require(presaleStatus[round], "Presale not start yet");
	   require(remainingToSell[round] > 0, "Token not available for presale");
	   
	   uint256 price = tokenPrice[round];
	   uint256 availableToken = remainingToSell[round];
	   uint256 tokens = amount * (10**18) / price;
	   
	   if(tokens > availableToken)
	   {
	       amount = availableToken * price / 10**18;
		   (bool success, ) = address(paymentWallet).call{value: address(this).balance}("");
           require(success, "ETH Payment failed");
		   
           _buytokens(amount, availableToken, address(msg.sender), round);		  
	   } 
	   else
	   {
           (bool success, ) = address(paymentWallet).call{value: address(this).balance}("");
           require(success, "ETH Payment failed");
		   
		   _buytokens(amount, tokens, address(msg.sender), round);
	   }
	   emit TokensBought(address(msg.sender), tokens, amount, block.timestamp);
    }
	
	function _buytokens(uint256 amount, uint256 tokens, address buyer, uint256 round) internal {
		USDRaised += amount; 
		remainingToSell[round] -= tokens;
		tokensSold += tokens;
		
		mapBuyTokenInfo[address(buyer)].USDPaid += amount;
		mapBuyTokenInfo[address(buyer)].tokenFromBuy += tokens;
	    IERC20(VENUSPEPE).safeTransfer(address(buyer), tokens);
	}
	
	function changeRoundPrice(uint256 round, uint256 price) external onlyOwner {
       require(tokenPrice.length > round, "Incorrect token round");
	   
       tokenPrice[round] = price;
	   emit RoundPriceUpdated(round, price);
    }
	
	function changePaymentWallet(address newPWallet) external onlyOwner {
       require(newPWallet != address(0), "address cannot be zero");
	   
       paymentWallet = newPWallet;
	   emit PaymentWalletUpdated(newPWallet);
    }
	
	function updatePreSaleStatus(bool status, uint256 round) external onlyOwner{
        require(presaleStatus[round] != status, "Presale is already set to that value");
		require(address(VENUSPEPE) != address(0), "VENUSPEPE contract not updated yet");
		if(status)
		{
		   require(IERC20(VENUSPEPE).balanceOf(address(this)) >= (remainingToSell[0] + remainingToSell[1]), "Stop the claim to start the presale");
		}
        presaleStatus[round] = status;
		emit PreSaleStatusUpdated(status);
    }
	
	function setVENUSPEPEaddress(address _address) external onlyOwner {
	    require(address(_address) != address(0), "Zero address");
	    require(address(VENUSPEPE) == address(0), "VENUSPEPE contract already set");
		
	    VENUSPEPE = _address;
		emit VENUSPEPEUpdated(VENUSPEPE);
    }
	
	function getLatestPrice() public view returns (uint256) {
       (, int256 price, , , ) = aggregatorInterface.latestRoundData();
       price = (price * (10 ** 10));
       return uint256(price);
    }
	
	function migrateTokens(uint256 amount) external onlyOwner{
	   require(IERC20(VENUSPEPE).balanceOf(address(this)) >= amount, "Insufficient Balance on contract");
	   require(!presaleStatus[0] && !presaleStatus[1], "Stop presale to migrate tokens");
	   
	   IERC20(VENUSPEPE).safeTransfer(address(msg.sender), amount);
       emit MigrateTokens(amount);
    }
}