// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

// -------------------------------------------------------------------------------------
//    _______ .___________. __    __  .___  ___.      ___      ___   ___  -----------
//   |   ____||           ||  |  |  | |   \/   |     /   \     \  \ /  /  ---------
//   |  |__   `---|  |----`|  |__|  | |  \  /  |    /  ^  \     \  V  /   -------
//   |   __|      |  |     |   __   | |  |\/|  |   /  /_\  \     >   <    -----
//   |  |____     |  |     |  |  |  | |  |  |  |  /  _____  \   /  .  \   ---
//   |_______|    |__|     |__|  |__| |__|  |__| /__/     \__\ /__/ \__\  --
//                                                                        -
// -----------------------------------------------------------------------

contract ethmax {
    
	using SafeMath for uint256;
	
	uint256 constant public MIN_AMOUNT = 0.1 ether;
	uint256 constant public GAS_FEE_SUBSIDE = 0.02 ether;
	
	uint256 constant public BASE_PERCENT = 1390; 
	
	uint256[] public REFERRAL_PERCENTS = [5000000, 2000000, 1000000];
	uint256 constant public PL_SHARE = 10000000;
	uint256 constant public PERCENTS_DIVIDER = 100000000; // 1000000 = 1%
	
	uint256 constant public CONTRACT_BALANCE_STEP = 100 ether;
	uint256 constant public TIME_STEP = 1 minutes; 
    uint256 constant public TIME_STEP2 = 1 hours; 
    
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	address payable public PL_Address;
	address public EMAX_TokenAddress;
	
	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 bonus;
		uint256 UserTotalWithdrawn;
	}
	mapping (address => User) internal users;
	
	mapping (address => uint256) internal ethMaxTokensToClaim;
	
	constructor(address payable PoolAddr, address _ethMaxTokenAddress) public {
		PL_Address = PoolAddr;
		EMAX_TokenAddress = _ethMaxTokenAddress;
	}


// Add ETH Function. 
// if no referrer, referrer = 0x0000000000000000000000000000000000000000
	function add(address referrer) external payable {
		require(msg.value >= MIN_AMOUNT);
		
        (bool success, ) = PL_Address.call{value: msg.value.mul(PL_SHARE).div(PERCENTS_DIVIDER)}("");
        require(success, "Transfer failed.");
		
		User storage user = users[msg.sender];

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
        
        /***Airdrop of tokens**/
        uint256 ethMaxTokens = calculateAirdropTokens(msg.value);
        ethMaxTokensToClaim[msg.sender] = ethMaxTokensToClaim[msg.sender].add(ethMaxTokens);
        //////////////
		msg.sender.transfer(GAS_FEE_SUBSIDE);

	}
	 /***Airdrop of tokens**/
	function calculateAirdropTokens(uint256 investment) internal pure returns (uint256){
	    return investment.mul(500);
	}
	
// Withdraw Function. Will withdraw all pending profits & referral rewards.
	function withdraw() external {
		User storage user = users[msg.sender];
		uint256 userTotalRate = getUserTotalRate(msg.sender);
		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userTotalRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userTotalRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
					dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); 
				totalAmount = totalAmount.add(dividends);

			}
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.bonus = 0;
		}

		require(totalAmount > 0, "User has no profits");
                    
		uint256 contractBalance = address(this).balance;
		require(totalAmount < contractBalance.mul(1000000).div(PERCENTS_DIVIDER), "Exceed limit");

		user.checkpoint = block.timestamp;
		
		msg.sender.transfer(totalAmount);

        user.UserTotalWithdrawn = user.UserTotalWithdrawn.add(totalAmount);
        
		totalWithdrawn = totalWithdrawn.add(totalAmount);
	}

//Claim EMAX Airdrop
	function claim() external {
	    require(ethMaxTokensToClaim[msg.sender] > 0, "nothing pending to claim");
	    /***Airdrop of tokens**/
        uint256 tokensToClaim = ethMaxTokensToClaim[msg.sender];
        ethMaxTokensToClaim[msg.sender] = 0;
        require(IERC20(EMAX_TokenAddress).transfer(msg.sender, tokensToClaim), "airdrop failed");
	}

//get ETHmax Contract Balance
	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

//get ETHmax Boost Rate 
	function getBoostRate() public view returns (uint256) {
		uint256 contractBalance = address(this).balance;
		return min(contractBalance.div(CONTRACT_BALANCE_STEP).mul(2), 5216);
	}
	
	
//get user Base Rate
    function getUserBaseRate(address userAddress) public view returns (uint256) {
        
        User storage user = users[userAddress];
        
        if(getUserTotalDeposits(userAddress) < 10 ether){
		return BASE_PERCENT;
        }
        
        if(getUserTotalDeposits(userAddress) >= 10 ether && getUserTotalDeposits(userAddress) < 20 ether){
		return BASE_PERCENT.add(70);
        }
        
		if(getUserTotalDeposits(userAddress) >= 20 ether){
		return BASE_PERCENT.add(140);
		}
	}

//get Current Return Rate
	function getCurrentReturnRate() public view returns (uint256){
	    return BASE_PERCENT.add(getBoostRate());
	}
	
//get Total Rate = Base Rate + Boost Rate + Hold Bonus Rate 
	function getUserTotalRate(address userAddress) public view returns (uint256) {
	    User storage user = users[userAddress];
		uint256 timeMultiplier;
		if (isActive(userAddress)) {
			timeMultiplier = min((now.sub(user.checkpoint)).div(TIME_STEP2).mul(2),348);
		} else {
			timeMultiplier = 0;
		}
	    return getUserBaseRate(userAddress).add(getBoostRate()).add(timeMultiplier);
	}
	   

// get user's total profits
	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userTotalRate = getUserTotalRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userTotalRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userTotalRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
					dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

			}

		}

		return totalDividends;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}
	
// get user's Referral Reward
	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

// get user's Available to withdraw
	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
				return true;
			}
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
	}


	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

// get user's total ETH added
	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}
	
// get user's profit-making eth amount
	function getUserProfitMakingEth(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 ethamount;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

			ethamount = ethamount.add(user.deposits[i].amount);
	    	}
		}
		
		return ethamount;
	}


// get user Total Withdrawded (Profits + Referral)
	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		return user.UserTotalWithdrawn;
	}
	
// get user Total Withdrawded Profits
	function getUserTotalWithdrawnDividends(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}

		return amount;
	}
	
// get user Total Earned
    function getUserTotalProfits(address userAddress) public view returns (uint256) {
         return getUserTotalWithdrawn(userAddress).add(getUserAvailable(userAddress));
    }
	
	
// get user earning status. 
    function getUserStatus (address userAddress) public view returns(bool) {
        User storage user = users[userAddress];
        uint256 A = getUserDividends(userAddress);
        uint256 B = getUserTotalWithdrawnDividends(userAddress);
        uint256 C = getUserTotalDeposits(userAddress).mul(2);
        if (A + B < C && user.deposits[0].amount > 0) {
            return true;
     }
    }
    
// get user pending EMAX. 
    function getUserPendingEMAX(address UserAddress) external view returns(uint256){
        return ethMaxTokensToClaim[UserAddress];
    }  
    
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

interface IERC20 {
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
}