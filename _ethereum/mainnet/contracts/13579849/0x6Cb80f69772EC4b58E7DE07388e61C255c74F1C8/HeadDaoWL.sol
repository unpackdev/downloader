pragma solidity ^0.8.0;


import "./Ownable.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeMath.sol";


interface HeadStaking {
    function depositsOf(address account) external view returns (uint256[] memory);
}

contract HeadDaoWL is Ownable {

	using Address for address;

	uint256 public totalBurnt;

	// $HEAD and staking contracts
	IERC20 public erc20Token;
	HeadStaking public stakingContract;

	// Whitelist parameters
	uint256 public slotPrice;
	uint256 public maxAvailable;
	uint256 public nClaimed;
	bool public sale_active = false;    
	

	// Whitelist storage
	address [] wallets;
	mapping(address => uint256) public investments;
	event whitelistAdded(address wallet, uint256 amount);


	// Sets up the $HEAD ERC20 and Head NFT Staking address
	function setInit(address erc20Address, address stakingAddress) public onlyOwner {
        erc20Token = IERC20(erc20Address);
        stakingContract = HeadStaking(stakingAddress);
    }

	// Sets the whitelist parameters, maxAvailable = the slots available for whitelist, slotPrice = price per slot (Decimal is 18)
	function initSale(uint256 headReq, uint256 limit) public onlyOwner {
		maxAvailable = limit;
		slotPrice = headReq;
		sale_active = true;

	}


	function closeSale() public onlyOwner {
        sale_active = false;
        
    }

	function startSale() public onlyOwner {
        sale_active = true;
        
    }


	function deposit(uint256 amount) public payable  {

		uint256[] memory deposits = stakingContract.depositsOf(_msgSender());

		require(sale_active, "Sale is not active" );
		require(!_msgSender().isContract(), "Contracts are not allowed");
		require(investments[_msgSender()] == 0, "Already Claimed");
		require(nClaimed < maxAvailable,"Whitelistis full");
		require(amount >= slotPrice, "Not enough head provided");
		require(erc20Token.balanceOf(_msgSender()) >= amount, "Not enough ERC20 tokens in wallet - 2");
		require(deposits.length > 0, "Staked ERC721 HEAD tokens required");

		erc20Token.transferFrom(_msgSender(), address(this), amount);

		totalBurnt += amount;
		investments[_msgSender()] = amount;
		wallets.push(_msgSender());
		nClaimed += 1 ;

		emit whitelistAdded(_msgSender(), amount);
	}


	function clear() public onlyOwner{

		for (uint i=0; i< wallets.length ; i++){
			delete investments[wallets[i]];
			delete wallets[i];
		}

		nClaimed = 0;
		


	}

	function getAll() public view returns (address[] memory){

		address[] memory ret = new address[](wallets.length);

        for (uint i = 0; i < wallets.length; i++) {
			if (wallets[i] != address(0)){
					ret[i] = wallets[i];
			}
        }
        return ret;
    }
}
