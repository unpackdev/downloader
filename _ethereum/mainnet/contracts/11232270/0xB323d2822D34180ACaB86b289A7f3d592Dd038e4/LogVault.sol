pragma solidity >=0.6.2;


///////////////////////////////////////////////////////////////////////
///							   Libraries							///
///////////////////////////////////////////////////////////////////////
library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;}

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;}

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;}
}


library Math {
	function max(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? y : x;
    }
	
	function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


///////////////////////////////////////////////////////////////////////
///							  Interfaces							///
///////////////////////////////////////////////////////////////////////
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
	
	function addInitialLiquidity() external payable;
}


interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}


interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

interface IApprover {
    function viewTotalExpLpBalance() external view returns (uint256);
    function approveStake(address who, uint256 lpAmount) external returns (uint256);
    function doRefund(address who, uint256 refundAmount) external;
}



///////////////////////////////////////////////////////////////////////
///							Vault Contract							///
///////////////////////////////////////////////////////////////////////
contract LogVault {
    using SafeMath for uint256;

	address internal immutable FACTORY;
	address internal immutable UNIROUTER;
    address internal immutable WETH;
	address internal immutable LOG;
	address internal immutable LOGxWETH;
	address internal immutable APPROVER;
	address internal immutable ADMIN_ADDRESS;

    constructor(address _FACTORY, address _UNIROUTER, address _LOG, address _APPROVER, address _LOGxWETH) public {
        FACTORY = _FACTORY;
        UNIROUTER = _UNIROUTER;
        WETH = IUniswapV2Router02(_UNIROUTER).WETH();
        LOG = _LOG;
        APPROVER = _APPROVER;
		LOGxWETH = _LOGxWETH;
		ADMIN_ADDRESS = msg.sender;
    }

	//store values of ln(x) multiplied by 1e6
	uint[10] lnValues = [0, 693147, 1098612, 1386294, 1609437, 1791759, 1945910, 2079441, 2197224, 2302585];

	//initial liquidity info
	uint public constant 	maxContributionETH 		= 	1000000000000000000; 	    //1 ETH
	uint public constant 	initialLiquidityETH 	= 	50000000000000000000; 	    //50 ETH
	uint private constant 	initialLiquidityLOG 	= 	27182000000000000000000; 	//27182 LOG

	uint private 	initialLP 				= 	Math.sqrt(initialLiquidityLOG.mul(initialLiquidityETH)).div(2);	//1165.8219907985620016/2  UNI-V2 LP tokens

	uint private 	stakingStartTime 		= 	27182818284;
	bool public 	allowStake 				= 	false;
	bool public 	liquidityAdded 			= 	false;

	//vault reward info
	uint256 private pendingRewards;
	uint256 public rewardAmount;
	uint256 public totalPoints;
	uint256 public logPerPoint;

	//dev fee, 4.5% of rewards
	uint256 private devFee = 45;
	uint256 private pendingDevRewards;

	//user info
	struct UserInfo {
		uint256 timePooled;
		uint256 lockupSeconds;
		uint256 lockupWeeks;

		uint256 ETHContributed;
		uint256 LPTokenBalance;
		uint256 points;
		uint256 logDebt;

		uint256 logReward;
	}

	mapping(address => UserInfo) public userInfo;


    //info about EXP LP stakers
	address[] public expStaker;
	mapping(address => bool) public stakerInList;

    mapping (address => uint256) public expLpBalances;
    mapping (address => uint256) public expLpLockup;

    receive() external payable {
		if(msg.sender != UNIROUTER){
			stakeETH(1);
		}
    }

    event AssignLP(address indexed owner, uint userLogLp);

    event DepositETH(address indexed owner, uint amount, uint lockup, uint lpTokenGot);
    event DepositLP(address indexed owner, uint amount, uint lockup);
    event DepositExpLP(address indexed owner, uint amount, uint lockup);

    event WithdrawLP(address indexed owner, uint amount);
    event WithdrawLOG(address indexed caller, address indexed owner, uint amount);


///////////////////////////////////////////////////////////////////////
///							Admin functions							///
///////////////////////////////////////////////////////////////////////

	//ADMIN-function: allow staking
	function allowStaking() public {
	    require(msg.sender == ADMIN_ADDRESS, "Caller is not admin.");
	    allowStake = true;
	}


	//ADMIN-function: create uniswap pair
    function addInitialLiquidity() public {
		require(!liquidityAdded, "Uniswap pair has already been created.");
		require(msg.sender == ADMIN_ADDRESS, "Caller is not admin.");
		require(address(this).balance >= initialLiquidityETH);

		//add liquidity to uniswap pair
        IERC20(LOG).addInitialLiquidity{value: initialLiquidityETH}();
		liquidityAdded = true;

		//get total LP amounts
		uint256 expLpTotal = IApprover(APPROVER).viewTotalExpLpBalance();
		uint256 logLpTotal = initialLP.mul(15).div(100);

		//assign lp tokens to expLP stakers
		address user;
		uint256 userLogLp;
		uint256 userShare;

		uint256 i;
		for (i = 0; i < expStaker.length; i++) {

		    //get user info
		    user = expStaker[i];

		    //user share and user amount
		    userShare = expLpBalances[user].mul(1e12).div(expLpTotal);
		    userLogLp = logLpTotal.mul(userShare).div(1e12);

			//reset user balance
			expLpBalances[user] = 0;

			// if LOG amount is greater than 0, update user info
			if (userLogLp > 0) {
				updateUser(user, expLpLockup[user], userLogLp);
				emit AssignLP(user, userLogLp);
			}
		}

		//set start time and allow stake again
		stakingStartTime = block.timestamp;
		allowStake = true;
    }



///////////////////////////////////////////////////////////////////////
///							Miscellaneous							///
///////////////////////////////////////////////////////////////////////


	//function to send ether
	function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


	//calc optimal fraction of ETH to swap for token based on 0.3% Uniswap fee, 9 decimals precision
	//a amount of ether available to buy
	//b amount of ether in liquidity pool
	function calcEthBuy(uint a, uint b) internal pure returns(uint fraction) {
		uint sqroot = Math.sqrt((a.mul(a).mul(9)).add(b.mul(a).mul(4e6)).add(b.mul(b).mul(4e6)));
		uint x = (sqroot.add(a.mul(3)).sub(b.mul(2000))).mul(1e18).div(a.mul(2000));

		return x.mul(a).div(1e18);
	}


	function calcLockupMulti(uint256 lockupWeeks) internal view returns(uint256 lockupMulti){
		//get lockup multiplier
		lockupMulti = lockupWeeks > 10 ? lnValues[9] : lnValues[lockupWeeks.sub(1)];
		lockupMulti = lockupMulti.add(1e6);
	}


	//claim refund of initial contribution if no uniswap pair is created within 1 week
	function refundInitial() public {
		require(!liquidityAdded, "Uniswap pair created, no refunds possible.");

		//get user info
		UserInfo storage user = userInfo[msg.sender];
		uint refundAmount = user.ETHContributed;

		require(block.timestamp >= user.timePooled + 1 weeks, "Refund will be possible 1 week after your contribution.");
		require(refundAmount > 0, "You have not contributed anything.");

		//update values
		user.timePooled = 0;
		user.lockupSeconds = 0;
		user.lockupWeeks = 0;
		user.LPTokenBalance = 0;
		user.ETHContributed = 0;
		user.points = 0;

		//send ETH back to staker
		sendValue(msg.sender, refundAmount);
	}

	//claim refund of initial EXP LP contribution if no uniswap pair is created within 1 week
	function refundInitialLP() public {
		require(!liquidityAdded, "Uniswap pair created, no refunds possible.");

		//get user info
		UserInfo storage user = userInfo[msg.sender];
		uint refundAmount = expLpBalances[msg.sender];

		require(block.timestamp >= user.timePooled + 1 weeks, "Refund will be possible 1 week after your contribution.");
		require(refundAmount > 0, "You have not contributed anything.");

		//update values
		user.timePooled = 0;
		user.lockupSeconds = 0;
		user.lockupWeeks = 0;
		user.LPTokenBalance = 0;
		user.ETHContributed = 0;
		user.points = 0;

		expLpBalances[msg.sender] = 0;
		expLpLockup[msg.sender] = 0;

		//send LP back to staker
		IApprover(APPROVER).doRefund(msg.sender, refundAmount);
	}



///////////////////////////////////////////////////////////////////////
///							 Vault Logic							///
///////////////////////////////////////////////////////////////////////

	//function to keep track of pending rewards, called on token transfer
    function addRewards(uint256 newRewards) public {
		require(msg.sender == LOG, "Can only be called from within LOG token transfers.");

        if(newRewards > 0) {

            uint256 diff = 0;
            uint256 currentReward = rewardAmount.add(newRewards);
            //check if there have been LOG tokens sent directly to Vault
            if (currentReward < IERC20(LOG).balanceOf(address(this))) {
                diff = IERC20(LOG).balanceOf(address(this)).sub(currentReward);
            }
            pendingRewards = pendingRewards.add(newRewards).add(diff);
            updateRewards();
        }
    }


	//update pending rewards and current LOG per point
	function updateRewards() internal {

		if (pendingRewards > 0) {
			if (totalPoints != 0) {
			    //update total reward amount
			    rewardAmount = rewardAmount.add(pendingRewards);

				uint256 logDevFee = pendingRewards.mul(devFee).div(1000);
				uint256 logReward = pendingRewards.sub(logDevFee);

				pendingDevRewards = pendingDevRewards.add(logDevFee);
				logPerPoint = logPerPoint.add(logReward.mul(1e12).div(totalPoints));

				//reset pending rewards
				pendingRewards = 0;
			}
		}
	}


	//update user information
	function updateUser(address who, uint256 lockup, uint256 lpTokenGot) internal {
		UserInfo storage user = userInfo[who];

		//store time information
        user.timePooled = block.timestamp;

		//if msg.sender is already staking and new lockup time is higher than previous one, replace it
		if (user.lockupSeconds < lockup.mul(1 weeks)) {
			user.lockupSeconds = lockup.mul(1 weeks);
			user.lockupWeeks = lockup;
		}

		//get lockup multiplier
		uint256 lockupMulti = calcLockupMulti(user.lockupWeeks);

		//assign LP tokens
        user.LPTokenBalance = user.LPTokenBalance.add(lpTokenGot);

		//assign points based on LP and lockup time
		uint256 userPointsBefore = user.points;
        user.points = user.LPTokenBalance.mul(lockupMulti).div(1e6);
		totalPoints = totalPoints.add(user.points).sub(userPointsBefore);

		//remember log debt to calculate future rewards
		user.logDebt = user.points.mul(logPerPoint).div(1e12);
	}


	//update pending user rewards
	function updatePending(address who) internal {
		UserInfo storage user = userInfo[who];

		//assign pending log rewards
		uint256 pendingLog = user.points.mul(logPerPoint).div(1e12).sub(user.logDebt);
		user.logReward = user.logReward.add(pendingLog);
	}



///////////////////////////////////////////////////////////////////////
///							Stake functions							///
///////////////////////////////////////////////////////////////////////

	//stake LP tokens
	function stakeLP(uint256 lockup, uint256 amount) public {
		require(lockup >= 1, "You must lock liquidity at least one week.");
		require(lockup <= 52, "Maximum lockup is 52 weeks.");
		require(amount > 0, "You need to stake at least 1 wei.");

		//if uniswap pair created stake normally
		if (liquidityAdded) {
			updateRewards();
			updatePending(msg.sender);
			stakeLogLP(lockup, amount);
		} else {
			stakeExpLP(lockup, amount);
		}
	}


	//stake EXP LP pre uniswap pair creation
	function stakeExpLP(uint256 lockup, uint256 lpAmount) internal {

		//call Approver contract to check allowance
		uint256 validAmount = IApprover(APPROVER).approveStake(msg.sender, lpAmount);

		expLpBalances[msg.sender] = expLpBalances[msg.sender].add(validAmount);
        expLpLockup[msg.sender] = lockup;

		//remember user if not in expStaker list yet
		if (!stakerInList[msg.sender]) {
		    expStaker.push(msg.sender);
		    stakerInList[msg.sender] = true;
		}

		emit DepositExpLP(msg.sender, lpAmount, lockup);
	}


	//stake LOG LP post uniswap pair creation
	function stakeLogLP(uint256 lockup, uint256 lpAmount) internal {

		//get lp from user - lp tokens need to be approved by user first
		require(IERC20(LOGxWETH).transferFrom(msg.sender, address(this), lpAmount), "Token transfer failed.");

		//update user variables
		updateUser(msg.sender, lockup, lpAmount);

		emit DepositLP(msg.sender, lpAmount, lockup);
	}


	//stake ETH
	function stakeETH(uint256 lockup) public payable {
		require(allowStake, "Staking has not been activated yet.");
		require(lockup >= 1, "You must lock liquidity at least one week.");
		require(lockup <= 52, "Maximum lockup is 52 weeks.");
		require(msg.value > 0, "You need to send ETH to stake.");

		uint lpTokenGot;

		//if uniswap pair created stake normally
		if (liquidityAdded) {
			updateRewards();
			updatePending(msg.sender);
			lpTokenGot = stakeUniswap();
		} else {
			lpTokenGot = stakeInitial();
		}

		//update user variables
		updateUser(msg.sender, lockup, lpTokenGot);

		emit DepositETH(msg.sender, msg.value, lockup, lpTokenGot);
	}


	//staking pre uniswap pair creation
	function stakeInitial() internal returns (uint256 lpTokenGot){
		UserInfo storage user = userInfo[msg.sender];
		require(user.ETHContributed < maxContributionETH, "You cannot contribute more than 1 ETH during initial staking.");

		uint currentEthBalance = (address(this).balance).sub(msg.value);
		require(currentEthBalance < initialLiquidityETH, "Initial Liquidity Target reached. Please wait for Uniswap pair creation.");

		uint validAmount;
		//maximum amount to be contributed
		uint maxAmount = Math.min(initialLiquidityETH.sub(currentEthBalance), maxContributionETH.sub(user.ETHContributed));


		//check total contribution
		if (msg.value > maxAmount) {
			validAmount = maxAmount;
			//assign contributed ETH
			user.ETHContributed = user.ETHContributed.add(validAmount);
			//return remaining eth
			sendValue(msg.sender, (msg.value).sub(validAmount));
		} else {
			validAmount = msg.value;
			//assign contributed ETH
			user.ETHContributed = user.ETHContributed.add(validAmount);
		}

		//disable staking if target is reached
		if (address(this).balance >= initialLiquidityETH) {
		    allowStake = false;
		}

		//share of initial liquidity, 2 decimals precision
		uint lpShare = uint(10000).mul(validAmount).div(initialLiquidityETH);

		//amount of LP tokens
		lpTokenGot = initialLP.mul(lpShare).mul(85).div(1000000);
	}


	//staking post uniswap pair creation
    function stakeUniswap() internal returns (uint256){

		//get liquidity pool information
        uint ethAmount = IERC20(WETH).balanceOf(LOGxWETH); //WETH in Uniswap

        //get current LOG amount held by vault
        uint logAmountBefore = IERC20(LOG).balanceOf(address(this));

		//calc optimal amount of ETH to
		uint ethBuy = calcEthBuy(address(this).balance, ethAmount);

		//define swap path: ETH->WETH->LOG
		address[] memory path = new address[](2);
		path[0] = WETH;
		path[1] = LOG;
		//swap ETH for LOG
		IUniswapV2Router02(UNIROUTER).swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethBuy}(1, path, address(this), block.timestamp + 30 minutes);

		//get amount of LOG bought
        uint logAmount = IERC20(LOG).balanceOf(address(this)).sub(logAmountBefore);

		//if buy of LOG was successfull, add liquidity
		require(logAmount > 0, "LOG Buy was not successfull.");
		require(IERC20(LOG).approve(UNIROUTER, logAmount), "Approve failed.");

		(uint logAdded , , uint lpTokenGot) = IUniswapV2Router02(UNIROUTER).addLiquidityETH{value: address(this).balance}(LOG, logAmount, 1, 1, address(this), block.timestamp + 15 minutes);

		//add log dust to pending rewards
		pendingRewards = pendingRewards.add(logAmount.sub(logAdded));

		return lpTokenGot;
    }



///////////////////////////////////////////////////////////////////////
///						Withdraw functions							///
///////////////////////////////////////////////////////////////////////

	//Withdraw LP tokens
    function withdrawLP(uint amount) public {
		UserInfo storage user = userInfo[msg.sender];

        require(Math.max(user.timePooled, stakingStartTime) + user.lockupSeconds <= block.timestamp, "You must wait longer.");
		require(user.LPTokenBalance >= amount, "Amount needs to be less than or equal to what is available.");
		require(amount > 0, "You need to withdraw at least 1 wei.");

		//update vault rewards
		updateRewards();
		//update user rewards
		updatePending(msg.sender);

        //update LPTokenBalance
        user.LPTokenBalance = user.LPTokenBalance.sub(amount);

		// update points
		uint256 lockupMulti = calcLockupMulti(user.lockupWeeks);
		uint256 userPointsBefore = user.points;
        user.points = user.LPTokenBalance.mul(lockupMulti).div(1000000);
		totalPoints = totalPoints.sub(userPointsBefore.sub(user.points));

        //send LP to user
        require(IERC20(LOGxWETH).transfer(msg.sender, amount), "LP Token transfer failed.");

		//update user logDebt and reset lockup time
		user.logDebt = user.points.mul(logPerPoint).div(1e12);
		user.lockupSeconds = 0;

		emit WithdrawLP(msg.sender, amount);
    }


	//Withdraw rewarded LOG, can be called by anyone for anyone to avoid LOG getting stuck in the Vault
    function withdrawLOG(address who) public {
		UserInfo storage user = userInfo[who];

		//update vault rewards
		updateRewards();
		//update user rewards
		updatePending(who);

		uint256 amount = user.logReward;
		require(amount > 0, "Withdraw amount needs to be at least 1 wei.");

		//transfer all LOG rewards to user
		user.logReward = 0;
		rewardAmount = rewardAmount.sub(amount);
		IERC20(LOG).transfer(who, amount);

		//update user logDebt
		user.logDebt = user.points.mul(logPerPoint).div(1e12);

		emit WithdrawLOG(msg.sender, who, amount);
    }


	//Withdraw Dev Reward, can be called by anyone to avoid LOG getting stuck in the Vault
	function withdrawDevReward() public {
		require(pendingDevRewards > 0, "Withdraw amount needs to be at least 1 wei.");

		//transfer all LOG to ADMIN_ADDRESS
		uint256 amount = pendingDevRewards;
		pendingDevRewards = 0;
		rewardAmount = rewardAmount.sub(amount);
		IERC20(LOG).transfer(ADMIN_ADDRESS, amount);
	}



///////////////////////////////////////////////////////////////////////
///							View functions							///
///////////////////////////////////////////////////////////////////////

	//get total value locked (TVL)
    function viewTotalValueLocked() public view returns (uint, uint) {

        uint wethPool = IERC20(WETH).balanceOf(LOGxWETH); //WETH in uniswap pool
        uint logPool = IERC20(LOG).balanceOf(LOGxWETH); //LOG in uniswap pool
		uint lpTokenAmount = IERC20(LOGxWETH).balanceOf(address(this)); //lp token held by contract

		uint wethShare = wethPool.mul(lpTokenAmount).div(IERC20(LOGxWETH).totalSupply());
		uint logShare = logPool.mul(lpTokenAmount).div(IERC20(LOGxWETH).totalSupply());

        return (wethShare, logShare);
    }


	//get ETH/LOG price
	function viewPoolInfo() public view returns (uint, uint) {
		uint wethPool = IERC20(WETH).balanceOf(LOGxWETH); //WETH in uniswap pool
        uint logPool = IERC20(LOG).balanceOf(LOGxWETH); //LOG in uniswap pool

		return (wethPool, logPool);
	}


	//get token release time
	function viewTokenReleaseTime(address who) public view returns (uint) {
		UserInfo storage user = userInfo[who];

		if (user.lockupSeconds == 0) {
		    return 0;
		} else {
		    return (Math.max(user.timePooled, stakingStartTime) + user.lockupSeconds);
		}
	}


	//get user LOG amount
	function viewUserLogAmount(address who) public view returns (uint) {
	    UserInfo storage user = userInfo[who];

		uint256 pendingLog = user.points.mul(logPerPoint).div(1e12).sub(user.logDebt);
		return user.logReward.add(pendingLog);
	}
}