pragma solidity >=0.6.2;


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



interface IERC20M {
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
    
	function mint(address account, uint256 amount) external;
	function burn(uint256 amount) external;
}


interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}


interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
}

interface IRektsurance {
    function startTimer() external;
}


contract EulerStaker {
    using SafeMath for uint256;
	
	address internal immutable FACTORY;
	address internal immutable UNIROUTER;
    address internal immutable WETH;
	address internal immutable EXP;
    address internal immutable REKT;
	address payable immutable REKTSURANCE;
	address internal immutable ADMIN_ADDRESS;

    constructor(address _FACTORY, address _UNIROUTER, address _WETH, address _EXP, address _REKT, address payable _REKTSURANCE) public {
        FACTORY = _FACTORY;
        UNIROUTER = _UNIROUTER;
        WETH = _WETH;
        EXP = _EXP;
        REKT = _REKT;
		REKTSURANCE = _REKTSURANCE;
		ADMIN_ADDRESS = msg.sender;
    }
    
    mapping(address => uint256) public timePooled;
    mapping(address => uint256) public LPTokenBalance;
    mapping(address => uint256) public RektTokenBalance;
	mapping(address => uint256) public lockupTime;
	mapping(address => uint256) public currentAPY;
	mapping(address => uint256) public referralBonus;
	mapping(address => uint256) private internalTime;
    mapping(address => uint256) private ETHContributed;
    mapping(address => uint256) private rewards;
    mapping(address => address) private referrer;
	
	bool public liquidityAdded = false;
	uint constant initialLiquidityETH = 50000000000000000000; 	//50 ETH
	uint constant initialLiquidityEXP = 2718281828459045235; 	//2.71828 EXP
	uint private initialLP = Math.sqrt(initialLiquidityEXP.mul(initialLiquidityETH)); 	//11.658219907985620016  UNI-V2 LP tokens
	uint private maxContributionETH = 2000000000000000000; 		//2 ETH
	
	uint private stakingStartTime = 1611736098;
	bool private allowStake = false;
	
    receive() external payable {
		if(msg.sender != UNIROUTER){
			stake(address(0), 1);
		}
    }
    
	
	//function to send ether
	function sendValue(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
	
	
	//calc optimal fraction of ETH to swap for token based on 0.3% Uniswap fee, 9 decimals precision
	//a amount of ether available to buy
	//b amount of ether in liquidity pool
	function calcEthBuy(uint a, uint b) internal pure returns(uint fraction) {
		uint sqroot = Math.sqrt((a.mul(a).mul(9)).add(b.mul(a).mul(4000000)).add(b.mul(b).mul(4000000)));
		uint x = (sqroot.add(a.mul(3)).sub(b.mul(2000))).mul(100000000000).div(a.mul(2000));
		
		return x.mul(a).div(100000000000);
	}
	
	
	//calc APY based on lockup period, in percent
	function eulerAPY(uint lockupDays) internal pure returns(uint){
		uint lockup = lockupDays.mul(2);
		return ( (271**lockup).div(100**lockup) );
	}
	
	
	//burn EXP dust
	function burnDust() public {
	    uint dustAmount = IERC20M(EXP).balanceOf(address(this));
		IERC20M(EXP).burn(dustAmount);
	}
	
	
	//ADMIN-function: allow staking
	function allowStaking() public {
	    require(msg.sender == ADMIN_ADDRESS, "Caller is not admin.");
	    allowStake = true;
	}
	
    
	//ADMIN-function: create uniswap pair
    function addInitialLiquidity() public {
        require(!liquidityAdded, "Uniswap pair has already been created.");
		require(msg.sender == ADMIN_ADDRESS, "Caller is not admin.");
		require(IERC20M(EXP).approve(UNIROUTER, initialLiquidityEXP), "Approve failed.");
        liquidityAdded = true;
		
		//mint initial supply
        IERC20M(EXP).mint(address(this), initialLiquidityEXP);
		
		//add liquidity
        IUniswapV2Router02(UNIROUTER).addLiquidityETH{ value: initialLiquidityETH }(EXP, initialLiquidityEXP, 1, 1, address(this), block.timestamp + 15 minutes);
		
		//start stake timer rektsurance
		IRektsurance(REKTSURANCE).startTimer();
		
		//set start time
		stakingStartTime = block.timestamp;
    }
	
	
	//claim refund of initial contribution if no uniswap pair is created within 1 week
	function refundInitial() public {
		require(!liquidityAdded, "Uniswap pair created, no refunds possible.");
		require(block.timestamp >= timePooled[msg.sender] + 1 weeks, "Refund will be possible 1 week after your contribution.");
		require(ETHContributed[msg.sender] > 0, "You have not contributed anything.");
		
		//get refundAmount and update values
		uint refundAmount = ETHContributed[msg.sender];
		LPTokenBalance[msg.sender] = 0;
		ETHContributed[msg.sender] = 0;
		rewards[msg.sender] = 0;
		
		//send ETH back to staker
		sendValue(msg.sender, refundAmount);
	}
	
	
	//stake
	function stake(address payable ref, uint256 lockup) public payable {
		require(allowStake, "Staking has not been activated yet.");
		require(lockup >= 1, "You must stake at least one day.");
		require(msg.value > 0, "You need to send ETH to stake.");
		
		//remember referrer for later use
		if(referrer[msg.sender] == address(0)) {
		    if (ref != msg.sender) {
		        referrer[msg.sender] = ref;
		    }
        }
		
		//if uniswap pair created stake normally
		if (liquidityAdded) {
			stakeUniswap();
		} else {
			stakeInitial();
		}
		
		//add recently earned reward
		rewards[msg.sender] = rewards[msg.sender].add(viewRecentRewardTokenAmount(msg.sender));
		//store information
        timePooled[msg.sender] = block.timestamp; //start time
        internalTime[msg.sender] = block.timestamp; //initialize internal time
		//if msg.sender is already staking and new lockup time is higher than previous one, replace it
		//if not leave it as is
		if(lockupTime[msg.sender] < lockup.mul(1 days)){
			lockupTime[msg.sender] = lockup.mul(1 days); //time the tokens are locked in days
			currentAPY[msg.sender] = eulerAPY(lockup);
		}
	}
	
	
	//staking pre uniswap pair creation
	function stakeInitial() internal {
		uint currentEthBalance = (address(this).balance).sub(msg.value);
		require(ETHContributed[msg.sender] < maxContributionETH, "You cannot contribute more than 2.5 ETH during initial staking.");
		require(currentEthBalance < initialLiquidityETH, "Initial Liquidity Target reached. Please wait for Uniswap pair creation.");
		
		uint validAmount;
		//maximum amount to be contributed
		uint maxAmount = Math.min(initialLiquidityETH.sub(currentEthBalance), maxContributionETH.sub(ETHContributed[msg.sender]));
		

		//check total contribution
		if (msg.value > maxAmount) {
			validAmount = maxAmount;
			//assign contributed ETH
			ETHContributed[msg.sender] = ETHContributed[msg.sender].add(validAmount);
			//return remaining eth
			sendValue(msg.sender, (msg.value).sub(validAmount));
		} else {
			validAmount = msg.value;
		}
		
		//share of initial liquidity, 2 decimals precision
		uint lpShare = uint(10000).mul(validAmount).div(initialLiquidityETH);
		
		//amount of LP tokens 
		uint lpTokenGot = initialLP.mul(lpShare).div(10000);
		
		//assign LP tokens
        LPTokenBalance[msg.sender] = LPTokenBalance[msg.sender].add(lpTokenGot);
		
		//assign contributed ETH
		ETHContributed[msg.sender] = ETHContributed[msg.sender].add(validAmount);
	}
	
	
	//staking post uniswap pair creation
    function stakeUniswap() internal {
		
		//send insurance fee (35%) to rektsurance contract
		sendValue(REKTSURANCE, address(this).balance.mul(35).div(100));
        
		//get liquidity pool information
		address pairAddress = IUniswapV2Factory(FACTORY).getPair(EXP, WETH);
        uint ethAmount = IERC20M(WETH).balanceOf(pairAddress); //WETH in Uniswap
		
		//calc optimal amount of ETH to
		uint ethBuy = calcEthBuy(address(this).balance, ethAmount);
		
		//define swap path: ETH->WETH->EXP
		address[] memory path = new address[](2);
		path[0] = WETH;
		path[1] = EXP;
		//swap ETH for EXP
		uint[] memory amounts = IUniswapV2Router02(UNIROUTER).swapExactETHForTokens{value: ethBuy}(1, path, address(this), block.timestamp + 30 minutes);
        
		//get amount of EXP bought
        uint expAmount = amounts[amounts.length-1];
		
		//allow pool to get tokens
		require(IERC20M(EXP).approve(UNIROUTER, expAmount), "Approve failed.");
		
		//if buy of EXP was successfull, add liquidity
		require(expAmount > 0, "EXP Buy was not successfull.");
		(uint expAdded, ,uint lpTokenGot) = IUniswapV2Router02(UNIROUTER).addLiquidityETH{value: address(this).balance}(EXP, expAmount, 1, 1, address(this), block.timestamp + 15 minutes);
		uint expDust = expAmount.sub(expAdded);
		
		//add remaining EXP dust to rewards
		rewards[msg.sender] = rewards[msg.sender].add(expDust);
		
		//map rektsurance tokens to msg.sender
		RektTokenBalance[msg.sender] = RektTokenBalance[msg.sender].add(msg.value);
		//mint 1.15*msg.value to this address; corresponds to 4.57% dev fee (15/115 * 35/100 = 21/460)
		IERC20M(REKT).mint(address(this), (msg.value).mul(115).div(100));
		
		//assign LP tokens
        LPTokenBalance[msg.sender] = LPTokenBalance[msg.sender].add(lpTokenGot);
    }


	//Withdraw LP tokens
    function withdrawLPTokens(uint amount) public {
        require(Math.max(timePooled[msg.sender], stakingStartTime) + lockupTime[msg.sender] <= block.timestamp, "You must wait longer.");
		require(LPTokenBalance[msg.sender] >= amount, "Amount needs to be less than or equal to what is available.");
		
		//withdraw amount in percent, 4 decimals precision
		uint withdrawPercent = amount.mul(1000000).div(LPTokenBalance[msg.sender]);
		
        //update RektTokenBalance and burn REKT
		uint burnREKT = RektTokenBalance[msg.sender].mul(withdrawPercent).div(1000000);
		RektTokenBalance[msg.sender] = RektTokenBalance[msg.sender].sub(burnREKT);
		IERC20M(REKT).burn(burnREKT);
		//update staking reward
        rewards[msg.sender] = viewExpTokenAmount(msg.sender);
        //update LPTokenBalance
        LPTokenBalance[msg.sender] = LPTokenBalance[msg.sender].sub(amount);
        
        //send tokens
        address pairAddress = IUniswapV2Factory(FACTORY).getPair(EXP, WETH);
        require(IERC20M(pairAddress).transfer(msg.sender, amount), "LP Token transfer failed.");
        
        //update timer
        lockupTime[msg.sender] = 0;
		internalTime[msg.sender] = block.timestamp;
    }
    
	
	//Withdraw rewarded EXP
    function withdrawRewardTokens(uint amount) public {
        require(Math.max(timePooled[msg.sender], stakingStartTime) + lockupTime[msg.sender] <= block.timestamp, "You must wait longer.");
        
        //get current reward amount and check for balance
        uint rewardAmount = viewExpTokenAmount(msg.sender);
		require(rewardAmount >= amount, "Amount needs to be less than or equal to what is available.");
		
		//withdraw amount in percent, 4 decimals precision
		uint withdrawPercent = amount.mul(1000000).div(rewardAmount);
		
        //update RektTokenBalance and burn REKT
		uint burnREKT = RektTokenBalance[msg.sender].mul(withdrawPercent).div(1000000);
		RektTokenBalance[msg.sender] = RektTokenBalance[msg.sender].sub(burnREKT);
		IERC20M(REKT).burn(burnREKT);
		//update staking reward
        rewards[msg.sender] = rewardAmount.sub(amount); //staker
        referralBonus[referrer[msg.sender]] = referralBonus[referrer[msg.sender]].add(amount.div(20)); //referrer
        
        //send reward to staker
        IERC20M(EXP).mint(msg.sender, amount);
        
        //update timer
        lockupTime[msg.sender] = 0;
		internalTime[msg.sender] = block.timestamp;
    }
	
	
	//Withdraw referral bonus
	function withdrawReferralEarned(uint amount) public{   
		require(referralBonus[msg.sender] >= amount, "Amount needs to be less than or equal to what is available.");
        referralBonus[msg.sender] = referralBonus[msg.sender].sub(amount);
        IERC20M(EXP).mint(msg.sender, amount);
    }
	
	
	//Withdraw insurance token
	function withdrawInsuranceToken(uint amount) public{
		require(timePooled[msg.sender] + lockupTime[msg.sender] <= block.timestamp, "You must wait longer.");
		require(RektTokenBalance[msg.sender] >= amount, "Amount needs to be less than or equal to what is available.");
		
		//remaining amount in percent, 4 decimals precision
		uint remainPercent = uint(1000000).sub(amount.mul(1000000).div(RektTokenBalance[msg.sender]));
		
		//update LPTokenBalance
		LPTokenBalance[msg.sender] = LPTokenBalance[msg.sender].mul(remainPercent).div(1000000);
		//update staking reward
        rewards[msg.sender] = (rewards[msg.sender].add(viewRecentRewardTokenAmount(msg.sender))).mul(remainPercent).div(1000000);
        //update RektTokenBalance
		RektTokenBalance[msg.sender] = RektTokenBalance[msg.sender].sub(amount);
        
        //send insurance token to staker
        IERC20M(REKT).transfer(msg.sender, amount);
        
        //update timer
        lockupTime[msg.sender] = 0;
		internalTime[msg.sender] = block.timestamp;
	}


	//calc reward since last withdraw
    function viewRecentRewardTokenAmount(address who) internal view returns (uint){
		uint stakedSeconds = block.timestamp.sub(internalTime[who]);
        return (viewPooledExp(who).mul(currentAPY[who]).mul(stakedSeconds).div(365).div(100).div(1 days));
    }
    
	//get amount of pooled EXP of who
    function viewPooledExp(address who) internal view returns (uint){
        
        if (liquidityAdded) {
            address pairAddress = IUniswapV2Factory(FACTORY).getPair(EXP, WETH);
            uint tokenAmount = IERC20M(EXP).balanceOf(pairAddress);
            return (tokenAmount.mul(LPTokenBalance[who])).div(IERC20M(pairAddress).totalSupply());
        } else {
            return (initialLiquidityEXP.mul(LPTokenBalance[who]).div(initialLP));
        }
    }
	
	
	//get EXP token balance
	function viewExpTokenAmount(address who) public view returns (uint){
        return rewards[who].add(viewRecentRewardTokenAmount(who));
    }
    
	
	//get total value locked (TVL)
    function viewTotalValueLocked() public view returns (uint, uint){
	
        address pairAddress = IUniswapV2Factory(FACTORY).getPair(EXP, WETH);
		
        uint wethPool = IERC20M(WETH).balanceOf(pairAddress); //weth in uniswap pool
        uint expPool = IERC20M(EXP).balanceOf(pairAddress); //exp in uniswap pool
		uint lpTokenAmount = IERC20M(pairAddress).balanceOf(address(this)); //lp token hold by contract
		
		uint wethShare = wethPool.mul(lpTokenAmount).div(IERC20M(pairAddress).totalSupply());
		uint expShare = expPool.mul(lpTokenAmount).div(IERC20M(pairAddress).totalSupply());
        
        return (wethShare, expShare);
    }
	
	
	//get token release time
	function viewTokenReleaseTime(address who) public view returns (uint) {
		return (Math.max(timePooled[who], stakingStartTime) + lockupTime[who]);
	}
}