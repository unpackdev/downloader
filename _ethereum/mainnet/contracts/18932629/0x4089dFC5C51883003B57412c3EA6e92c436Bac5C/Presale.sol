//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./SafeERC20.sol";
import "./Ownable.sol";

interface Aggregator {
   function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract Presale is Ownable{
    using SafeERC20 for IERC20;
	
	uint256 public tokenToClaim;
	uint256 public tokenSold;
    uint256 public USDRaised;
	uint256 public currentStage;
	uint256 public startTime;
	uint256 public USDThreshold;
	
	address public burnWallet;
	address public AIM;
	address public USDT;
	Aggregator public aggregatorInterface;
	
	bool public claimStatus;
	bool public presaleStatus;
	
	uint256[5]  public tokenToSell;
	uint256[5]  public remainingToSell;
	uint256[][] public tokenPrice;
	
	struct buyTokenInfo {
	  uint256 USDPaid;
	  uint256 tokenFromBuy;
      uint256 clamedToken; 	  
    }
	
	mapping(address => buyTokenInfo) public mapBuyTokenInfo;
	
    event TokensBought(address user, uint256 tokens, uint256 amount);
	event TokensClaimed(address user, uint256 amount, uint256 timestamp);
	event PresaleStatusUpdated(bool status);
	
    constructor() {
	   tokenToSell = [30000000  * 10**18, 30000000 * 10**18, 30000000 * 10**18, 30000000 * 10**18, 30000000 * 10**18];
	   remainingToSell = [30000000  * 10**18, 30000000 * 10**18, 30000000 * 10**18, 30000000 * 10**18, 30000000 * 10**18];
	   
	   tokenPrice.push([10000, 13700, 17400, 21100]);
	   tokenPrice.push([24800, 28500, 32200, 35900]);
	   tokenPrice.push([39600, 43300, 47000, 50700]);
	   tokenPrice.push([54400, 58100, 61800, 65500]);
	   tokenPrice.push([69200, 72900, 76600, 80300]);
	   
	   USDThreshold = 25000 * 10**6;
		
	   aggregatorInterface = Aggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
	   burnWallet = address(0x000000000000000000000000000000000000dEaD);
	   AIM = address(0xf69c3A5Be775c92898735Ff4E1Fe99fE6Ec89813);
	   USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
	}
	
	function buyWithUSDT(uint256 amount) external {
	   require(amount > 0, "Amount must be greater than zero");
	   require(presaleStatus, "Presale not start yet");
	   require(IERC20(USDT).balanceOf(address(msg.sender)) >= amount, "USDT amount not available to buy tokens");
	   require(IERC20(USDT).allowance(address(msg.sender), address(this)) >= amount, "Make sure to add enough USDT allowance");
	   require(USDThreshold >= (amount + mapBuyTokenInfo[address(msg.sender)].USDPaid), "Buy limit exceeded");
	   
	   uint256 currentRound = (block.timestamp - startTime) / 604800;
	   if(currentRound > 3)
	   {
	       _updateStage();
	   }
	   if(currentStage > 4)
	   {
	       presaleStatus = false;
		   claimStatus = true;
	   }
	   else
	   {
	       uint256 round = (block.timestamp - startTime) / 604800;
		           round = round > 3 ? 3 : round;
		   uint256 price = tokenPrice[currentStage][round];
		   
		   uint256 remainingToken = remainingToSell[currentStage];
		   uint256 requestedToken = amount * (10**18) / price;
		  
		   if(requestedToken > remainingToken)
		   {
			   amount = remainingToken * price / 10**18;
			   IERC20(USDT).safeTransferFrom(address(msg.sender), address(this), amount);
			   _buytokens(amount, remainingToken, address(msg.sender));	
			   emit TokensBought(address(msg.sender), remainingToken, amount);		   
		   } 
		   else
		   {
			   IERC20(USDT).safeTransferFrom(address(msg.sender), address(this), amount);
			   _buytokens(amount, requestedToken, address(msg.sender));
			   emit TokensBought(address(msg.sender), requestedToken, amount);
		   }
	   }
    }
	
	function buyWithETH() external payable {
	   uint256 amount = (getLatestPrice() * msg.value) / (10**30);
	   require(amount > 0, "Amount must be greater than zero");
	   require(presaleStatus, "Presale not start yet");
	   require(USDThreshold >= amount + mapBuyTokenInfo[address(msg.sender)].USDPaid, "Buy limit exceeded");
	   
	   uint256 currentRound = (block.timestamp - startTime) / 604800;
	   if(currentRound > 3)
	   {
	       _updateStage();
	   }
	   if(currentStage > 4)
	   {
	       presaleStatus = false;
		   claimStatus = true;
	   }
	   else
	   {
	      uint256 round = (block.timestamp - startTime) / 604800;
		          round = round > 3 ? 3 : round;
		  uint256 price = tokenPrice[currentStage][round];
		  
		  uint256 remainingToken = remainingToSell[currentStage];
		  uint256 requestedToken = amount * (10**18) / price;
		  
		  if(requestedToken > remainingToken)
		  {
			 amount = remainingToken * price / 10**18;
			 _buytokens(amount, remainingToken, address(msg.sender));	
			 emit TokensBought(address(msg.sender), remainingToken, amount);		   
		  } 
		  else
		  {
			 _buytokens(amount, requestedToken, address(msg.sender));
			 emit TokensBought(address(msg.sender), requestedToken, amount);
		  }	 
	   }
    }
	
	function privateSaleBuyers(uint256[] calldata tokens, address[] calldata buyers) external onlyOwner {
	   require(tokens.length == buyers.length, "Error: Array lengths do not match");
	   require(!presaleStatus && !claimStatus, "Presale is already start");
	   
	   for(uint256 i = 0; i < tokens.length; i++)
	   {
		   require(tokens[i] > 0, "Tokens must be greater than zero");
		   require(buyers[i] != address(0), "address cannot be zero");
   
		   uint256 price = tokenPrice[currentStage][0];
		   uint256 amount = tokens[i] * price / 10**18;
		   
		   require(USDThreshold >= (amount + mapBuyTokenInfo[address(buyers[i])].USDPaid), "Buy limit exceeded");
		   require(remainingToSell[currentStage] >= tokens[i], "Token not available for sale");
		   
		   _buytokens(amount, tokens[i], address(buyers[i]));
		   emit TokensBought(address(buyers[i]), tokens[i], amount);
	    } 
    }
	
	function _buytokens(uint256 amount, uint256 tokens, address buyer) internal {
		USDRaised += amount; 
		remainingToSell[currentStage] -= tokens;
		tokenSold += tokens;
		tokenToClaim += tokens;
		
		if(remainingToSell[currentStage] == 0)
		{
		   currentStage += 1;
		   startTime = block.timestamp;
		}
		if(currentStage > 4)
		{
		   presaleStatus = false;
		   claimStatus = true;
		}
		mapBuyTokenInfo[address(buyer)].USDPaid += amount;
		mapBuyTokenInfo[address(buyer)].tokenFromBuy += tokens;
	}
	
	function _updateStage() internal {
	    uint256 tokenToBurn = remainingToSell[currentStage];
	    if(tokenToBurn > 0)
	    {
		   IERC20(AIM).safeTransfer(address(burnWallet), tokenToBurn);
	    }
	    startTime += 2419200;
	    currentStage += 1;
	}
	
	function startPresale() external onlyOwner{
        require(!presaleStatus && !claimStatus, "Presale is already start");
		require(IERC20(AIM).balanceOf(address(this)) >= 150000000 * 10**18, "Token not available to start presale");
		
		startTime = block.timestamp;
        presaleStatus = true;
		emit PresaleStatusUpdated(true);
    }
	
	function claimToken() external{
		require(claimStatus, "Claim not start yet");
		
		uint256 pending = mapBuyTokenInfo[address(msg.sender)].tokenFromBuy - mapBuyTokenInfo[address(msg.sender)].clamedToken;
		if(pending > 0) 
		{
		    mapBuyTokenInfo[address(msg.sender)].clamedToken += pending;
		    IERC20(AIM).safeTransfer(address(msg.sender), pending);
		    emit TokensClaimed(address(msg.sender), pending, block.timestamp);
		}
    }
	
    function withdrawETH(address receiver, uint256 amount) public onlyOwner {
	   require(receiver != address(0), "address cannot be zero");
	   require(address(this).balance >= amount, "Tokens must be greater than zero");
	   
       (bool success, ) = address(receiver).call{value: amount}("");
	   require(success, "ETH withdraw failed");
    }
	
    function withdrawUSDT(address receiver, uint256 amount) public onlyOwner {
	   require(receiver != address(0), "address cannot be zero");
	   require(IERC20(USDT).balanceOf(address(this)) >= amount, "Tokens must be greater than zero");
	   
	   IERC20(USDT).safeTransfer(address(receiver), amount);
    }
	
	function getLatestPrice() public view returns (uint256) {
       (, int256 price, , , ) = aggregatorInterface.latestRoundData();
       price = (price * (10 ** 10));
       return uint256(price);
    }
}