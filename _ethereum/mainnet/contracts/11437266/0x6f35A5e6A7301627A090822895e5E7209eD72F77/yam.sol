pragma solidity >= 0.5.0 < 0.6.0;

import "./TokenInfoLib.sol";
import "./SymbolsLib.sol";
import "./SafeMath.sol";
import "./SignedSafeMath.sol";
import "./Ownable.sol";
import "./SavingAccountParameters.sol";
import "./IERC20.sol";
import "./ABDK.sol";
import "./tokenbasic.sol";
import "./bkk.sol";

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;





/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}




interface AllPool{
    function is_Re(address user) view external  returns(bool);
    // function set_user_isRe(address user,address pool,string calldata name) external;
    function get_Address_pool(address user) view external  returns(address);
}

interface IPlayerBook {
    function settleReward( address from,uint256 amount ) external returns (uint256);
}
contract SavingAccount is Ownable{
	using TokenInfoLib for TokenInfoLib.TokenInfo;
	using SymbolsLib for SymbolsLib.Symbols;
	using SafeMath for uint256;
	using SignedSafeMath for int256;
	using SafeERC20 for IERC20;

	
	event depositTokened(address onwer,uint256 amount,address tokenaddress);
	event withdrawed(address onwer,uint256 amount,address tokenaddress);
	event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    
    
	bool _hasStart = false;
	uint256 public _initReward = 0;
	
	IERC20 public _pros = IERC20(0x306Dd7CD66d964f598B4D2ec92b5a9B275D7fEb3);
    address public _teamWallet = 0x89941E92E414c88179a830af5c10bde0E9245158;
	address public _playbook = 0x21A4086a6Cdb332c851B76cccD21aCAB6428D9E4;
	address public _allpool = 0xC682bD99eE552B6f7d931aFee2A9425806e155E9;
	

	address public _ETH = 0x000000000000000000000000000000000000000E;
	address public _USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
	address public _PROS = 0x306Dd7CD66d964f598B4D2ec92b5a9B275D7fEb3;
	uint256 DURATION = 1 days;
	
    int128 dayNums = 0;

    int128 baseReward = 80000;
    
    uint256 public base_ = 20*10e3;
    uint256 public rate_forReward = 1;
    uint256 public base_Rate_Reward = 100;

	struct Account {
		mapping(address => TokenInfoLib.TokenInfo) tokenInfos;
		bool active;
	}
// 	int256 public totalReward;
	mapping(address => Account) accounts;
	mapping(address => int256) totalDeposits;
	mapping(address => int256) totalLoans;
	mapping(address => int256) totalCollateral;
    mapping(address => bool) loansAccount;
	address[] activeAccounts;
	address[] activeLoansAccount;

    mapping(address => uint256)_initTokenReward;
    uint256 public _startTime =  now + 365 days;
    uint256 public _periodFinish = 0;
    uint256 public _rewardRate = 0;
    
    mapping(address =>uint256) public _rewardRateList;
    // uint256 public _lastUpdateTime;
    mapping(address=>uint256) public _lastUpdateTime;
    // uint256 public _rewardPerTokenStored;
    mapping(address=>uint256) public _rewardPerTokenStored;
    uint256 public _teamRewardRate = 0;
    uint256 public _poolRewardRate = 0;
    uint256 public _baseRate = 10000;
    uint256 public _punishTime = 10 days;
    
    uint256 public one_Rate = 90;
    uint256 public sec_Rate = 5;
    uint256 public thr_Rate = 5;
    uint256 public BASE_RATE_FORREWARD = 100;
    
    
    mapping(address => mapping(address=>uint256)) public _userRewardPerTokenPaid;
    mapping(address => mapping(address=>uint256)) public _rewards;
    mapping(address => mapping(address=>uint256)) public _lastStakedTime;
	SymbolsLib.Symbols symbols;
	int256 constant BASE = 10**6;
	int BORROW_LTV = 66; //TODO check is this 60%?
	int LIQUIDATE_THREADHOLD = 85;

	constructor() public {
		SavingAccountParameters params = new SavingAccountParameters();
		address[] memory tokenAddresses = params.getTokenAddresses();
		//TODO This needs improvement as it could go out of gas
		symbols.initialize(params.ratesURL(), params.tokenNames(), tokenAddresses);
		
	}


	function setprosToken(IERC20 token) public onlyOwner{
	    _pros = token;
	} 
	function setAllpool(address pool)public onlyOwner {
	    _allpool = pool;
	}
	 
	function setTeamToken(address tokenaddress) public onlyOwner{
	    _teamWallet = tokenaddress;
	}
	 
	function set_tokens(address eth,address usdt,address pros) public onlyOwner{
	    _ETH = eth;
	    _USDT = usdt;
	    _PROS = pros;
	}
	 
	function setPlaybook(address playbook) public onlyOwner{
	    _playbook = playbook;
	}
	
	function setRate_Reward(uint256 one,uint256 sec,uint256 thr,uint256 total)public onlyOwner{
	    one_Rate = one;
	    sec_Rate = sec;
	    thr_Rate = thr;
	    BASE_RATE_FORREWARD = total;
	}
	
	function() external payable {}
	
	function getAccountTotalUsdValue(address accountAddr) public view returns (int256 usdValue) {
		return getAccountTotalUsdValue(accountAddr, true).add(getAccountTotalUsdValue(accountAddr, false));
	}

	function getAccountTotalUsdValue(address accountAddr, bool isPositive) private view returns (int256 usdValue){
		int256 totalUsdValue = 0;
		for(uint i = 0; i < getCoinLength(); i++) {
			if (isPositive && accounts[accountAddr].tokenInfos[symbols.addressFromIndex(i)].totalAmount(block.timestamp) >= 0) {
				totalUsdValue = totalUsdValue.add(
					accounts[accountAddr].tokenInfos[symbols.addressFromIndex(i)].totalAmount(block.timestamp)
					.mul(int256(symbols.priceFromIndex(i)))
					.div(BASE)
				);
			}
			if (!isPositive && accounts[accountAddr].tokenInfos[symbols.addressFromIndex(i)].totalAmount(block.timestamp) < 0) {
				totalUsdValue = totalUsdValue.add(
					accounts[accountAddr].tokenInfos[symbols.addressFromIndex(i)].totalAmount(block.timestamp)
					.mul(int256(symbols.priceFromIndex(i)))
					.div(BASE)
				);
			}
		}
		return totalUsdValue;
	}
	
	
		
	function rewardPerToken(address tokenID) public view returns (uint256) { //to change to the address thing for dip problem 
        if (totalDeposits[tokenID] == 0) { //totalPower change ----- totaldipost[token] 
            return _rewardPerTokenStored[tokenID];
        }
        return
            _rewardPerTokenStored[tokenID].add(
                lastTimeRewardApplicable() 
                    .sub(_lastUpdateTime[tokenID])
                    .mul(_rewardRateList[tokenID]) //change for the _rewardRate[token]
                    .mul(1e18)
                    .div(uint256(totalDeposits[tokenID])) //change for the totalPower[token] ---- 
            );
    }
    
    
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, _periodFinish);
    }
    
    
    function earned(address account,address tokenID) public view returns (uint256) {
        return
            uint256(tokenBalanceOf(tokenID,account))
                .mul(rewardPerToken(tokenID).sub(_userRewardPerTokenPaid[tokenID][account]))
                .div(1e18)
                .add(_rewards[tokenID][account]); //one token
    }
	
	
	function earned(address account) public view returns (uint256) {
        uint coinsLen = getCoinLength();
        uint256 Total;
        for (uint i = 0; i < coinsLen; i++) {
			address tokenAddress = symbols.addressFromIndex(i);
			Total = Total.add(earned(account,tokenAddress));
		}
		return Total;
    }
	
	
    modifier checkHalve() {
        if (block.timestamp >= _periodFinish) {
            update_initreward();
            _pros.mint(address(this), _initReward);
            _rewardRate = _initReward.div(DURATION*3);
            _rewardRateList[address(_PROS)] = _initReward.mul(one_Rate).div(DURATION*BASE_RATE_FORREWARD);
            _rewardRateList[address(_USDT)] = _initReward.mul(sec_Rate).div(DURATION*BASE_RATE_FORREWARD);
            _rewardRateList[address(_ETH)] = _initReward.mul(thr_Rate).div(DURATION*BASE_RATE_FORREWARD);
            _periodFinish = block.timestamp.add(DURATION);
        }
        _;
    }
    
    modifier checkStart() {
        require(block.timestamp > _startTime, "not start");
        _;
    }
    
	modifier updateReward(address account,address tokenID) {
        _rewardPerTokenStored[tokenID] = rewardPerToken(tokenID);
        _lastUpdateTime[tokenID] = lastTimeRewardApplicable();
        if (account != address(0)) {
            _rewards[tokenID][account] = earned(account,tokenID);
            _userRewardPerTokenPaid[tokenID][account] = _rewardPerTokenStored[tokenID];
        }
        _;
    } 
    
    modifier isRegister(){
        require(AllPool(_allpool).is_Re(msg.sender)==true,"address not register or name already register");
        _;
    }
   
    
    modifier updateRewardAll(address account) {
        uint coinsLen = getCoinLength();
        address[] memory tokens = new address[](coinsLen);
        
        for (uint i = 0; i < coinsLen; i++) {
			address tokenAddress = symbols.addressFromIndex(i);
			tokens[i] = tokenAddress;
		}
        for(uint i=0;i<3;i++){
            address tokenID = tokens[i];
            _rewardPerTokenStored[tokenID] = rewardPerToken(tokenID);
            _lastUpdateTime[tokenID] = lastTimeRewardApplicable();
            if (account != address(0)) {
            _rewards[tokenID][account] = earned(account,tokenID);
            _userRewardPerTokenPaid[tokenID][account] = _rewardPerTokenStored[tokenID];
        }
        }
        _;
    }
	
	
	/** 
	 * Get the overall state of the saving pool
	 */
	function getMarketState() public view returns (address[] memory addresses,
		int256[] memory deposits
		)
	{
		uint coinsLen = getCoinLength();

		addresses = new address[](coinsLen);
		deposits = new int256[](coinsLen);


		for (uint i = 0; i < coinsLen; i++) {
			address tokenAddress = symbols.addressFromIndex(i);
			addresses[i] = tokenAddress;
			deposits[i] = totalDeposits[tokenAddress];
		}

		return (addresses, deposits);
	}

	/*
	 * Get the state of the given token
	 */
	function getTokenState(address tokenAddress) public view returns (int256 deposits, int256 loans, int256 collateral)
	{
		return (totalDeposits[tokenAddress], totalLoans[tokenAddress], totalCollateral[tokenAddress]);
	}

	/** 
	 * Get all balances for the sender's account
	 */
	
	function getBalances() public view returns (address[] memory addresses, int256[] memory balances)
	{
		uint coinsLen = getCoinLength();

		addresses = new address[](coinsLen);
		balances = new int256[](coinsLen);

		for (uint i = 0; i < coinsLen; i++) {
			address tokenAddress = symbols.addressFromIndex(i);
			addresses[i] = tokenAddress;
			balances[i] = tokenBalanceOf(tokenAddress);
		}

		return (addresses, balances);
	}

	function getActiveAccounts() public view returns (address[] memory) {
		return activeAccounts;
	}
    
    function tokenBalanceOf(address tokenAddress,address account) public view returns (int256 amount) {
		return accounts[account].tokenInfos[tokenAddress].totalAmount(block.timestamp);
	}

	function getCoinLength() public view returns (uint256 length){
		return symbols.getCoinLength();
	}

	function tokenBalanceOf(address tokenAddress) public view returns (int256 amount) {
		return accounts[msg.sender].tokenInfos[tokenAddress].totalAmount(block.timestamp);
	}

	function getCoinAddress(uint256 coinIndex) public view returns (address) {
		return symbols.addressFromIndex(coinIndex);
	}

	/** 
	 * Deposit the amount of tokenAddress to the saving pool. 
	 */
	
	function depositToken(address tokenAddress, uint256 amount) updateReward(msg.sender,tokenAddress) checkHalve checkStart isRegister public payable {
		TokenInfoLib.TokenInfo storage tokenInfo = accounts[msg.sender].tokenInfos[tokenAddress];
		if (!accounts[msg.sender].active) {
			accounts[msg.sender].active = true;
			activeAccounts.push(msg.sender);
		}
        
		int256 currentBalance = tokenInfo.getCurrentTotalAmount();

		require(currentBalance >= 0,
			"Balance of the token must be zero or positive. To pay negative balance, please use repay button.");
        uint256 LastRatio = 0;
        
		// deposited amount is new balance after addAmount minus previous balance
		int256 depositedAmount = tokenInfo.addAmount(amount, LastRatio, block.timestamp) - currentBalance;
		totalDeposits[tokenAddress] = totalDeposits[tokenAddress].add(depositedAmount);
        emit depositTokened(msg.sender,amount,tokenAddress);
		receive(msg.sender, amount, amount,tokenAddress);
	}
	
	

	/**
	 * Withdraw tokens from saving pool. If the interest is not empty, the interest
	 * will be deducted first.
	 */
	 
	function withdrawToken(address tokenAddress, uint256 amount) updateReward(msg.sender,tokenAddress) checkStart checkHalve public payable {
		require(accounts[msg.sender].active, "Account not active, please deposit first.");
		TokenInfoLib.TokenInfo storage tokenInfo = accounts[msg.sender].tokenInfos[tokenAddress];

		require(tokenInfo.totalAmount(block.timestamp) >= int256(amount), "Insufficient balance.");
  		require(int256(getAccountTotalUsdValue(msg.sender, false).mul(-1)).mul(100) <= (getAccountTotalUsdValue(msg.sender, true) - int256(amount.mul(symbols.priceFromAddress(tokenAddress)).div(uint256(BASE)))).mul(BORROW_LTV));
        
        emit withdrawed(msg.sender,amount,tokenAddress);
		tokenInfo.minusAmount(amount, 0, block.timestamp);
		totalDeposits[tokenAddress] = totalDeposits[tokenAddress].sub(int256(amount));
		totalCollateral[tokenAddress] = totalCollateral[tokenAddress].sub(int256(amount));

		send(msg.sender, amount, tokenAddress);		
	}



	function receive(address from, uint256 amount, uint256 amounttwo,address tokenAddress) private {
		if (symbols.isEth(tokenAddress)) {
            require(msg.value >= amounttwo, "The amount is not sent from address.");
            msg.sender.transfer(msg.value-amounttwo);
		} else {
			require(msg.value >= 0, "msg.value must be 0 when receiving tokens");
			if(tokenAddress!=_USDT ){
			    require(IERC20(tokenAddress).transferFrom(from, address(this), amount));
			}else{
			    basic(tokenAddress).transferFrom(from,address(this),amount);
			}
		}
	}
	


	function send(address to, uint256 amount, address tokenAddress) private {
		if (symbols.isEth(tokenAddress)) {
			msg.sender.transfer(amount);
		} else {
		    if(tokenAddress!=_USDT){
			    require(IERC20(tokenAddress).transfer(to, amount));
			}else{
			    basic(tokenAddress).transfer(to, amount);
			}
		}
	}



    function getReward() public updateRewardAll(msg.sender) checkHalve checkStart {
        
        uint256 reward;
        uint coinsLen = getCoinLength();
        address[] memory tokens = new address[](coinsLen);
        
        for (uint i = 0; i < coinsLen; i++) {
			address tokenAddress = symbols.addressFromIndex(i);
			tokens[i] = tokenAddress;
			reward = reward.add(earned(msg.sender,tokens[i]));
		}
        if (reward > 0) {
            _rewards[tokens[0]][msg.sender] = 0;
            _rewards[tokens[1]][msg.sender] = 0;
            _rewards[tokens[2]][msg.sender] = 0;
            
            address set_play = AllPool(_allpool).get_Address_pool(msg.sender)==0x0000000000000000000000000000000000000000?_playbook:AllPool(_allpool).get_Address_pool(msg.sender);
            uint256 fee = IPlayerBook(set_play).settleReward(msg.sender,reward);
            if(fee>0){
                _pros.safeTransfer(set_play,fee);
            }
            
            uint256 teamReward = reward.mul(_teamRewardRate).div(_baseRate);
            if(teamReward>0){
                _pros.safeTransfer(_teamWallet, teamReward);
            }
            uint256 leftReward = reward.sub(fee).sub(teamReward);
            uint256 poolReward = 0;
            if(leftReward>0){
                _pros.safeTransfer(msg.sender, leftReward);
            }
            emit RewardPaid(msg.sender,reward);
        }
        
        
    }
 
   
	

	
	function update_initreward() private {
	    dayNums = dayNums + 1;
        uint256 thisreward = base_.mul(rate_forReward).mul(10**18).mul((base_Rate_Reward.sub(rate_forReward))**(uint256(dayNums-1))).div(base_Rate_Reward**(uint256(dayNums)));
	    _initReward = uint256(thisreward);
	}
	
	

    // set fix time to start reward
    function startReward(uint256 startTime)
        external
        onlyOwner
        updateReward(address(0),address(_ETH))
    {
        require(_hasStart == false, "has started");
        _hasStart = true;
        _startTime = startTime;
        update_initreward();
        _rewardRate = _initReward.div(DURATION*3); 
        _rewardRateList[address(_PROS)] = _initReward.mul(one_Rate).div(DURATION*BASE_RATE_FORREWARD);
        _rewardRateList[address(_USDT)] = _initReward.mul(sec_Rate).div(DURATION*BASE_RATE_FORREWARD);
        _rewardRateList[address(_ETH)] = _initReward.mul(thr_Rate).div(DURATION*BASE_RATE_FORREWARD);
        _pros.mint(address(this), _initReward);
        _lastUpdateTime[address(_ETH)] = _startTime;
        _lastUpdateTime[address(_USDT)] = _startTime;
        _lastUpdateTime[address(_PROS)] = _startTime; //for get the chushihua state
        _periodFinish = _startTime.add(DURATION);

        emit RewardAdded(_initReward);
    }    
}