pragma solidity ^0.5.17;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}

contract AopxCoin {

    address[] private stakedUsers;
    using SafeMath for uint256;
	uint256 constant private INITIAL_SUPPLY = 100000000e18;
	uint256 constant private TX_FEE = 8; // 8% per tx
	uint256 constant private POOL_FEE = 65; //8% per tx, 80% to pool
    uint256 constant private BURN_FEE = 25; //8% per tx, 10% to burn
	uint256 constant private DEV_FEE = 10;  // 8% per tx, 10% to dev
	uint256 constant private SAHRE_COLLECT = 50;  // 50% every collect
	uint256 constant private MIN_STAKE_AMOUNT = 10000e18; // 10,000 Tokens Needed
	mapping(uint256=>uint256) private SHARE_DIVIDENDS;//share per pool: [7,15,30] pool_7day_20%  pool_15day_30%  pool_30day_50% 
    mapping(address => User) private  users;
   
   
	string constant public name = "AopxCoin";
	string constant public symbol = "Aopx";
	uint8 constant  public decimals = 18;
    bool  private isDividending = false;
    
	struct Product {
		uint256 staked;
		uint256 unstakeTime;
	}
	
	struct User {
		uint256 balance;
		uint256 totalStaked;
		uint256 dividends;
		uint256 collectTime;
		mapping(address => uint256) allowance;
		mapping(uint256=>Product) pools;
	}
	
	struct PoolInfo{
	    uint256 totalStaked;
	    uint256 dividends;
	    uint256 pricePerToken;
	}
	

	struct Info {
		uint256 totalSupply;
		uint256 totalStaked;
		mapping(address => User) users;
	    mapping(uint256=>PoolInfo)  pools;//[7,15,30]
		address dev;
		address eater;
		address owner;
		address manager;
		address p1;
		address p2;
	}
	Info public info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	
	event Stake(address indexed owner, uint256 tokens);
	event Unstake(address indexed owner, uint256 tokens);
	event Collect(address indexed owner, uint256 tokens);
	event Tax(uint256 tokens);
	event Burn(uint256 tokens);
	

	constructor() public {
	    info.owner=msg.sender;
	    info.eater=address(0x0);
		info.dev = address(0x3450E1D5727AA85fe63283ddFE5f2B552ce9F1B1);
		info.manager = address(0x584f298694EeB2a786d22658e85c87A01700b8F0);
		info.p1=address(0xEe0d33c6cDb332b3472c59D04A48e48b354e07E5);
		info.p2=address(0x6b722E08FbFCC60e5c499aaCFe06Ceaf92303729);
		info.totalSupply = INITIAL_SUPPLY;
		info.users[info.p1].balance = 80000000e18;
		info.users[info.p2].balance = 20000000e18;
		SHARE_DIVIDENDS[7]=20;
		SHARE_DIVIDENDS[15]=30;
		SHARE_DIVIDENDS[30]=50;
		emit Transfer(address(0x0), info.p1, 80000000e18);
		emit Transfer(address(0x0), info.p2, 20000000e18);
	}

	function stakeCount() public  view returns (uint256 stakeCount) {
		return stakedUsers.length;
	}
	function stakedUser(uint256 index) public  view returns (address stakeUser) {
		return stakedUsers[index];
	}
	function stake(uint256 _tokens,uint256 dayType) external {
		_stake(_tokens,dayType);
	}
	function unstake(uint256 _tokens,uint256 dayType) external {
		_unstake(_tokens,dayType);
	}
	function collect() external returns (uint256) {
	    uint256 _dividends =info.users[msg.sender].dividends;
      	require(_dividends >= 0,"no dividends!");
		require(info.users[msg.sender].collectTime < now);
		info.users[msg.sender].dividends =	info.users[msg.sender].dividends.sub(_dividends.mul(SAHRE_COLLECT).div(100));
		info.users[msg.sender].balance  = 	info.users[msg.sender].balance.add(_dividends.mul(SAHRE_COLLECT).div(100));
		info.users[msg.sender].collectTime = now + 1 days;
		emit Transfer(address(this), msg.sender, _dividends);
		emit Collect(msg.sender, _dividends);
		return _dividends;
	}
	function dividend() external  {
	   require(msg.sender == info.manager, "Caller is not dev");
	   require(!isDividending,"sorry,dividending");
	   uint256 ss=stakedUsers.length;
	   	for (uint256 i = 0; i < ss; i++) {
	   	     address user=stakedUsers[i];
	   	     
		     uint256 _dividends = dividendsOf(user).sub(info.users[user].dividends);
	         if(_dividends > 0){
	                info.users[user].dividends += _dividends;
	         }else{
	             continue;
	         }
		}
	   
	   if(info.pools[7].totalStaked>0){
	     info.pools[7].dividends=0;
	   }
	   if(info.pools[15].totalStaked>0){
	     info.pools[15].dividends=0;
	    }
	   if(info.pools[30].totalStaked>0){
	     info.pools[30].dividends=0;
	     }
	}
    function changeDev(address _user) external {
		  require(msg.sender == info.owner, "Caller is not owner");
		  info.dev=_user;
	}
	function changeManage(address _user) external {
		  require(msg.sender == info.owner, "Caller is not owner");
		  info.manager=_user;
	}
	function dividendByIndex(uint256[] calldata indexs,bool finshed) external returns (uint256) {
	   require(msg.sender == info.manager||msg.sender == info.owner, "Caller is not owner");
	   uint256 length=indexs.length;
	   
	   for (uint256 i = 0; i < length; i++) {
	       address user=stakedUsers[indexs[i]];
		    uint256 _dividends = dividendsOf(stakedUsers[indexs[i]]).sub(info.users[user].dividends);
	         if(_dividends > 0){
	                info.users[user].dividends =info.users[user].dividends.add(_dividends);
	         }
		}
       
       if(finshed){
	   if(info.pools[7].totalStaked>0){
	     info.pools[7].dividends=0;
	   }
	   if(info.pools[15].totalStaked>0){
	     info.pools[15].dividends=0;
	    }
	   if(info.pools[30].totalStaked>0){
	     info.pools[30].dividends=0;
	     }
       }
	}
	function transfer(address _to, uint256 _tokens) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		return true;
	}
	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}
	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		require(info.users[_from].allowance[msg.sender] >= _tokens);
		info.users[_from].allowance[msg.sender] -= _tokens;
		_transfer(_from, _to, _tokens);
		return true;
	}
	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}
	function totalBurn() public view returns (uint256) {
		return info.users[info.eater].balance;
	}
    function totalDividends() public view returns (uint256) {
		return info.pools[7].dividends.add(info.pools[15].dividends).add(info.pools[30].dividends);
	}
	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance - stakedOf(_user,0);
	}
	function stakedOf(address _user,uint256 dayType) public view returns (uint256) {
	    
	  	require(dayType==0|| dayType==7||dayType==15||dayType==30,"product daytype not support");
	
		if(dayType==7){
		    return info.users[_user].pools[7].staked;
		}
		if(dayType==15){
		 return   info.users[_user].pools[15].staked;
		}
		if(dayType==30){
		   return info.users[_user].pools[30].staked;
		}
	    return info.users[_user].totalStaked;
	}
	function collectTimeOf(address _user) public view returns (uint256) {
		return info.users[_user].collectTime;
	}
	function stakedOfPool() public view returns (uint256,uint256,uint256) {
	    return (info.pools[7].totalStaked,info.pools[15].totalStaked,info.pools[30].totalStaked);
	}
	function dividendsOfPool() public view returns (uint256,uint256,uint256) {
		return (info.pools[7].dividends,info.pools[15].dividends,info.pools[30].dividends);
	}
	function dividendsOf(address _user) public view returns (uint256) {
		uint256 _7Amount =0;   
     	uint256 _15Amount = 0;  
		uint256 _30Amount =0; 
		if(info.pools[7].totalStaked>0){
		    _7Amount=(info.users[_user].pools[7].staked.mul(info.pools[7].dividends).div(info.pools[7].totalStaked));
		}
		if(info.pools[15].totalStaked>0){
		    _15Amount=info.users[_user].pools[15].staked.mul(info.pools[15].dividends).div(info.pools[15].totalStaked);
		}
		
		if(info.pools[30].totalStaked>0){
		    _30Amount=  info.users[_user].pools[30].staked.mul(info.pools[30].dividends).div(info.pools[30].totalStaked);
		}
		
	    uint256 amount= _7Amount.add(_15Amount).add(_30Amount).add(info.users[_user].dividends);
	    
	    return amount;
	}
	function allInfo(address _user) public view returns (uint256 tokenTotalSupply,uint256 tokenTotalStaked,uint256 tokenTotalDividends,uint256 tokenTotalBurn,uint256 userStake7,uint256 userStake15,uint256 userStake30,uint256 userDividendsTotal,uint256 userDividends,uint256 userUnstakeTime7,uint256 userUnstakeTime15,uint256 userUnstakeTime30,uint256 collectTime) {
		address user=_user;
		return (totalSupply(),info.totalStaked,totalDividends(),totalBurn(),stakedOf(user,7),stakedOf(user,15),stakedOf(user,30),dividendsOf(user),info.users[user].dividends,info.users[user].pools[7].unstakeTime,info.users[user].pools[15].unstakeTime,info.users[user].pools[30].unstakeTime, collectTimeOf(user));
	}
	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}
	function _transfer(address _from, address _to, uint256 _tokens) internal returns (uint256) {
		require(balanceOf(_from) >= _tokens);
		
		info.users[_from].balance = info.users[_from].balance.sub(_tokens);
		
		uint256 _taxAmount = _tokens.mul(TX_FEE).div(100);
		uint256 _poolAmount = _taxAmount.mul(POOL_FEE).div(100);
		uint256 _burnAmount = _taxAmount.mul(BURN_FEE).div(100);
		uint256 _devAmount = _taxAmount.mul(DEV_FEE).div(100);
		uint256 _realAmount = _tokens.sub(_taxAmount);

        
        info.users[_to].balance =info.users[_to].balance.add(_realAmount);
        info.users[info.dev].balance =info.users[info.dev].balance.add(_devAmount);
        info.users[info.eater].balance=info.users[info.eater].balance.add(_burnAmount);
        
        info.pools[7].dividends = info.pools[7].dividends.add(_poolAmount.mul(SHARE_DIVIDENDS[7]).div(100));
        info.pools[15].dividends =  info.pools[15].dividends.add(_poolAmount.mul(SHARE_DIVIDENDS[15]).div(100));
        info.pools[30].dividends=info.pools[30].dividends.add(_poolAmount.mul(SHARE_DIVIDENDS[30]).div(100));
        
        emit Transfer(_from, info.dev, _devAmount);
        emit Transfer(_from, info.eater, _burnAmount);
        emit Transfer(_from, _to, _realAmount);
        
        emit Tax(_taxAmount);
        emit Burn(_burnAmount);
        
        return _realAmount;
    }
    function _stake(uint256 _amount,uint256 dayType) internal {
      
        require(dayType==7||dayType==15||dayType==30,"product daytype not support");
		require(balanceOf(msg.sender) >= _amount);
		require(stakedOf(msg.sender,dayType).add(_amount) >= MIN_STAKE_AMOUNT,"min stake amount:50,000");
		

		info.users[msg.sender].pools[dayType].unstakeTime = now + dayType*86400;
		info.totalStaked = info.totalStaked.add(_amount);
		info.pools[dayType].totalStaked =info.pools[dayType].totalStaked.add(_amount);
		info.users[msg.sender].totalStaked= info.users[msg.sender].totalStaked.add(_amount);
		info.users[msg.sender].pools[dayType].staked = info.users[msg.sender].pools[dayType].staked.add(_amount);
		
	    _addStakedUser(msg.sender);
		emit Transfer(msg.sender, address(this), _amount);
		emit Stake(msg.sender, _amount);
	}
	function _unstake(uint256 _amount,uint256 dayType) internal {
	   	require(dayType==7||dayType==15||dayType==30,"product daytype not support");
	    require(info.users[msg.sender].pools[dayType].unstakeTime < now,"unstakeTime not arrive");
		require(stakedOf(msg.sender,dayType) >= _amount);
		
		info.totalStaked = info.totalStaked.sub(_amount);
		info.pools[dayType].totalStaked =info.pools[dayType].totalStaked.sub(_amount);
		info.users[msg.sender].pools[dayType].staked =	info.users[msg.sender].pools[dayType].staked.sub(_amount);
		info.users[msg.sender].totalStaked =info.users[msg.sender].totalStaked.sub(_amount);
		
		emit Unstake(msg.sender, _amount);
	}
	function _addStakedUser(address _address) internal {
	     
	     uint256 length=stakedUsers.length;
	     bool exist=false;
	     
             for (uint256 i = 0; i < length; i++) {
	      	    if(stakedUsers[i] == _address){
	      	       exist=true;
	      	       break;
	      	    }
	      	}
	      
	      if(!exist){
	           stakedUsers.push(_address);
	      }
	      	
	  }
}