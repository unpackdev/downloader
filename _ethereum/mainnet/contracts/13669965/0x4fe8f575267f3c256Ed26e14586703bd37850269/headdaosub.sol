pragma solidity ^0.8.0;


import "./Ownable.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Math.sol";


interface HeadStaking {
    function depositsOf(address account) external view returns (uint256[] memory);
}
interface headERC721 {
    function balanceOf(address account) external view returns (uint256);
}

contract HeadDAOSub is Ownable {
	using Address for address;

	// Head DAO Addresses
	IERC20 public erc20Token;
	HeadStaking public stakingContract;
	headERC721 public nftContract;

	bool public sale_active = false;  
	uint256 public totalBurnt;
	uint256 public initalPlanID = 0;
	uint256 public licenses = 4000;
	uint256 public nextPlanId;
	address [] wallets;

	// Structs and Mappings
	struct Subscription {address subscriber; uint256 start; uint256 nextPayment;}
	struct Plan {uint256 amount; uint256 frequency;}
	mapping(uint256 => Plan) public plans;
	mapping(address => Subscription) public subscriptions;
	

	function createPlan(uint256 amount, uint256 frequency) external onlyOwner {
		require(amount > 0, 'amount needs to be > 0');
		require(frequency > 0, 'frequency needs to be > 0');
		plans[nextPlanId] = Plan(amount, frequency);
		nextPlanId++;
	}

	modifier basics {
		require(sale_active, "Sale is not active" );
		require(!_msgSender().isContract(), "Contracts are not allowed");
		uint256[] memory deposits = stakingContract.depositsOf(_msgSender());
		uint256 balance = nftContract.balanceOf(_msgSender());
		require(Math.max(deposits.length, balance)> 0, "Staked ERC721 HEAD tokens required");

		_;
	}

	function purchase(uint256 planId) public payable basics{
		Subscription storage subscription = subscriptions[_msgSender()];
		Plan storage plan = plans[planId];
		uint256 active = activeSubs();

		require(planId == initalPlanID, "Initial Plan has to be selected");
		require(active <= licenses, "Max Amount of licenses Sold");
		require(subscription.start == 0, "Already Purchased Initial");
		require(erc20Token.balanceOf(_msgSender()) >= plan.amount, "Not enough ERC20 tokens in wallet - 2");


		erc20Token.transferFrom(_msgSender(), address(this), plan.amount);
		subscriptions[msg.sender] = Subscription(msg.sender, block.timestamp, block.timestamp + plan.frequency);
		wallets.push(_msgSender());

		totalBurnt += plan.amount;

		
	}

	function pay(uint planId) public payable basics{


		Subscription storage subscription = subscriptions[_msgSender()];
		Plan storage plan = plans[planId];
		uint256 active = activeSubs();

		require(plan.frequency > 0, "Plan does not Exist");
		require(subscription.start > 0, "Must Purchase Initial");
		require(active <= licenses, "Max Amount of licenses Sold");
		require(erc20Token.balanceOf(_msgSender()) >= plan.amount, "Not enough ERC20 tokens in wallet - 2");


		erc20Token.transferFrom(_msgSender(), address(this), plan.amount);
		
		subscription.nextPayment = Math.max(subscription.nextPayment,block.timestamp) + plan.frequency;
		
		totalBurnt += plan.amount;


	}


	function activeSubs() public view returns (uint256){

		uint256 active = 0;
        for (uint i = 0; i < wallets.length; i++) {
			Subscription storage subscription = subscriptions[wallets[i]];
			if (subscription.nextPayment >= block.timestamp){
					active++;
			}
        }
        return active;
    }


	// Sets up the $HEAD ERC20, Head NFT Staking abd HEAD NFT ERC721 address
	function setInit(address erc20Address, address stakingAddress, address headAddress) public onlyOwner {
        erc20Token = IERC20(erc20Address);
        stakingContract = HeadStaking(stakingAddress);
		nftContract = headERC721(headAddress);
    }


	function closeSale() public onlyOwner {
        sale_active = false;
        
    }

	function startSale() public onlyOwner {
        sale_active = true;
        
    }

	function changeInitialPlanID(uint256 newplanId) public onlyOwner {
		initalPlanID = newplanId;

	}

	function changeLicenses(uint256 newLicenses) public onlyOwner {
		licenses = newLicenses;

	}
}
