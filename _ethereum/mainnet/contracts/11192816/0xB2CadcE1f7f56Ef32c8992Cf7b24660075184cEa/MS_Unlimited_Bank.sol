/**
 *Submitted for verification at Etherscan.io on 2020-11-03
*/

pragma solidity ^0.5.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract MS_Unlimited_Bank {
    using SafeMath for uint256;

    // 1%
	uint256 constant public BASE_PERCENT = 10;

	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public CONTRACT_BALANCE_STEP = 100 * (10 ** 18);
	uint256 constant public INVEST_MIN_AMOUNT = 1 *(10 **18);
	uint256 constant public TIME_STEP = 1 days;
	
	// 用户总量
	uint256 public totalUsers;
    // 资金池存入总量
	uint256 public totalInvested;
    // 总提币
	uint256 public totalWithdrawn;
    // 总存入笔数
	uint256 public totalDeposits;
	// Ms 合约地址
	address public MS;
		
	// 用户
	struct Deposit {
		uint256 amount;     // 存入数量
		uint256 withdrawn;  // 提出数量
		uint256 start;      // 存入时间
	}
	struct User {
		Deposit[] deposits;     // n笔存款
		uint256 checkpoint;     // 提币时间 ｜ 初次充币时间 （以当前时间计算24小时利率）
		address referrer;       // 上级
		uint256 inviteRate;          // 推荐奖励 利率 
	}
	mapping (address => User) internal users;
	
	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);

    constructor(address _ms) public{
        MS = _ms;
    }
    
	 // 充值
	function invest(address referrer,uint256 value) public {
	    require(value >= INVEST_MIN_AMOUNT,"Minimum recharge 1 MS ");
        IERC20(MS).transferFrom(msg.sender,address(this),value);
        
	    User storage user = users[msg.sender];
		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            // 添加上级并计算邀请利率
            user.referrer = referrer;
            uint256 amount = getUserTotalDeposits(referrer);
            if (value >= amount){
                users[referrer].inviteRate = user.inviteRate.add(10);
            }else{
                users[referrer].inviteRate = user.inviteRate.add((value.mul(10)).div(amount));
            }
		}
		
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}
		user.deposits.push(Deposit(value, 0, block.timestamp));
		totalInvested = totalInvested.add(value);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, value);
	}
	
	// 提现
	function withdraw() public {
		User storage user = users[msg.sender];
		// 总利率
	    uint256 userPercentRate = totalInterestRate(msg.sender);
	   
	    uint256 totalAmount;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
		    // 2倍出局
		    if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {
		        // 以当前这笔存款起始时间计算利息
		        if (user.deposits[i].start > user.checkpoint) {
		            dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
		        }else{
		            // 以起始时间计算利息
		            dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
		        }
		        // 利息高于本金2倍 减掉 多余利息
		        if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
                    dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				}
				// 添加提币数量
				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);
		    }
		}
		
		require(totalAmount > 0, "User has no dividends");
		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		user.checkpoint = block.timestamp;
		IERC20(MS).transfer(msg.sender,totalAmount);
		totalWithdrawn = totalWithdrawn.add(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
	}
	
	// 利息计算
	function getUserDividends(address userAddress) public view returns (uint256) {
	    User storage user = users[userAddress];
	    // 总利率
	    uint256 userPercentRate = totalInterestRate(userAddress);
	    // 总利息
		uint256 totalDividends;

		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
		    if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {
		        if (user.deposits[i].start > user.checkpoint) {
		            dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);
		        }else{
		            dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
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
    
	// 合约利率：10 + (合约总额 / 100ETH)
	function getContractBalanceRate() public view returns (uint256) {
		return BASE_PERCENT.add(address(this).balance.div(CONTRACT_BALANCE_STEP));
	}
	
	// 用户利率： (当前时间 - 起始时间) / 86400 * 10
	function getUserPercentRate(address userAddress) public view returns (uint256){
	    User storage user = users[userAddress];
	    if (isActive(userAddress)) {
	        return ((now.sub(user.checkpoint)).div(TIME_STEP)).mul(10);
	    }
        return 0;
	}
	
	// 邀请利率
	function getUserInviteRate(address userAddress) public view returns(uint256){
	    return users[userAddress].inviteRate;
	}
	
	// 总利率 = 合约利率 + 用户利率 + 邀请利率
	function totalInterestRate(address userAddress) public view returns(uint256){
	    return getContractBalanceRate().add(getUserPercentRate(userAddress)).add(getUserInviteRate(userAddress));
	}
	
	// 获取合约余额
	function getContractBalance() public view returns (uint256) {
		return IERC20(MS).balanceOf(address(this));
	}

	// 获取用户24h收益开始计算时间点
	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}
	
	// 获取用户推荐人 (上级)
	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}
	
	// 获取用户存款信息
	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];
		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
	}

    // 获取用户存入笔数
	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}
	
	// 获取用户存入总额
	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
		uint256 amount;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}
		return amount;
	}
	
	// 获取用户提币总额
	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
		uint256 amount;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}
		return amount;
	}
	
	// 是否活跃
	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];
		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
				return true;
			}
		}
	}
}