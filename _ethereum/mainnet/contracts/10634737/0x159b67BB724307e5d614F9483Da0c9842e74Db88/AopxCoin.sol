/**
 *Submitted for verification at Etherscan.io on 2020-08-09
*/

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

    using SafeMath for uint256;
	uint256 constant private INITIAL_SUPPLY = 100000000e18;
	uint256 constant private TX_FEE = 8; // 8% per tx
	uint256 constant private POOL_FEE = 65; //8% per tx, 80% to pool
    uint256 constant private BURN_FEE = 25; //8% per tx, 10% to burn
	uint256 constant private DEV_FEE = 10;  // 8% per tx, 10% to dev
	uint256 constant private SAHRE_COLLECT = 50;  // 50% every collect
	uint256 constant private MIN_STAKE_AMOUNT = 10000e18; // 10,000 Tokens Needed
   
   
	string constant public name = "AopxCoin";
	string constant public symbol = "Aopx";
	uint8 constant public decimals = 18;

    
	struct Product {
		uint256 staked;
		uint256 unstakeTime;
		uint256 dividends;
		uint256 dividendsGiveOut;
	}
	
	struct User {
		uint256 balance;
		uint256 dividends;
		uint256 collectTime;
		mapping(address => uint256) allowance;
		mapping(uint256=>Product) pools;
	}
	
	struct PoolInfo{
	    uint256 totalStaked;
	    uint256 dividends;
	    uint256 dividendsGiveOut;
	}
	

	struct Info {
		uint256 totalSupply;
		mapping(address => User) users;
	    mapping(uint256=>PoolInfo)  pools;//[7,15,30]
		address dev;
		address eater;
		address owner;
		address manager;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	
	event Stake(address indexed owner, uint256 tokens,uint256 day);
	event Unstake(address indexed owner, uint256 tokens,uint256 day);
	event Collect(address indexed owner, uint256 tokens);
	event Tax(uint256 tokens);
	

	constructor() public {
		info.totalSupply = INITIAL_SUPPLY;
	    info.owner=msg.sender;
	    info.eater=address(0x0);
		info.dev = address(0x3450E1D5727AA85fe63283ddFE5f2B552ce9F1B1);
		info.manager =address(0x584f298694EeB2a786d22658e85c87A01700b8F0);
		address p1=address(0xEe0d33c6cDb332b3472c59D04A48e48b354e07E5);
		address p2=address(0x6b722E08FbFCC60e5c499aaCFe06Ceaf92303729);
		info.users[p1].balance = 80000000e18;
		info.users[p2].balance = 20000000e18;
		emit Transfer(address(0x0), p1, 80000000e18);
		emit Transfer(address(0x0), p2, 20000000e18);
	}

	function stake(uint256 _tokens,uint256 day) external {
		_stake(_tokens,day);
	}
	function unstake(uint256 _tokens,uint256 day) external {
		_unstake(_tokens,day);
	}

	function collect() external returns (uint256) {
	    
	    require(info.users[msg.sender].collectTime < now,"time..");
       
        
		uint256 _dividends7	=dividendsOf(msg.sender,7);
		uint256 _dividends15 =dividendsOf(msg.sender,15);
		uint256 _dividends30 =dividendsOf(msg.sender,30);
		
		require( (info.users[msg.sender].dividends >0 || _dividends7 > 0 || _dividends15 > 0||_dividends30 > 0),"no dividends");
		info.users[msg.sender].collectTime = now + 86400;
		info.pools[7].dividendsGiveOut =info.pools[7].dividendsGiveOut.add(_dividends7);
		info.pools[15].dividendsGiveOut =info.pools[15].dividendsGiveOut.add(_dividends15);
		info.pools[30].dividendsGiveOut =info.pools[30].dividendsGiveOut.add(_dividends30);
		
		uint256 _dividends=_dividends7.add(_dividends15).add(_dividends30).add(info.users[msg.sender].dividends);
		
		info.users[msg.sender].dividends = _dividends.mul(SAHRE_COLLECT).div(100);
		info.users[msg.sender].balance  = 	info.users[msg.sender].balance.add(_dividends.mul(SAHRE_COLLECT).div(100));
		
		emit Transfer(address(this), msg.sender, _dividends);
		emit Collect(msg.sender, _dividends);
		
		return _dividends;
	}
	
	function dividendsOf(address _user,uint256 day) public view returns (uint256) {

		if(info.pools[day].totalStaked > 0 && info.users[msg.sender].collectTime <= now ){
		  return  (info.users[_user].pools[day].staked.mul(info.pools[day].dividends).div(info.pools[day].totalStaked));
		}else{
		    return 0;
		}
	   
	}
	function clear() external {
	    require(msg.sender == info.manager, "Caller is not owner");
	    if(info.pools[7].dividends<= info.pools[7].dividendsGiveOut){
	        	info.pools[7].dividends=0;
	    }else{
	        	info.pools[7].dividends = info.pools[7].dividends.sub(info.pools[7].dividendsGiveOut);
	    }
	
	    if(info.pools[15].dividends<= info.pools[15].dividendsGiveOut){
	        	info.pools[15].dividends=0;
	    }else{
	        	info.pools[15].dividends = info.pools[15].dividends.sub(info.pools[15].dividendsGiveOut);
	    }
	    
	     if(info.pools[30].dividends<= info.pools[30].dividendsGiveOut){
	        	info.pools[30].dividends=0;
	    }else{
	        	info.pools[30].dividends = info.pools[30].dividends.sub(info.pools[30].dividendsGiveOut);
	    }
		
		info.pools[7].dividendsGiveOut=0;
		info.pools[15].dividendsGiveOut=0;
		info.pools[30].dividendsGiveOut=0;
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
	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance - info.users[_user].pools[7].staked-info.users[_user].pools[15].staked-info.users[_user].pools[30].staked;
	}

	function allInfo(address user) public view returns( uint256 totalBurn, uint256 totalStaked7,uint256 totalStaked15,uint256 totalStaked30,uint256 dividends7,uint256 dividends15,uint256 dividends30, uint256 staked7,uint256 staked15,uint256 staked30, uint256 userDividends,uint256 userBalance,uint256 collectTime){
	      address _user=user;
	      return ( info.users[info.eater].balance,info.pools[7].totalStaked,info.pools[15].totalStaked,info.pools[30].totalStaked,info.pools[7].dividends,info.pools[15].dividends,info.pools[30].dividends,info.users[_user].pools[7].staked,info.users[_user].pools[15].staked,info.users[_user].pools[30].staked,info.users[_user].dividends,balanceOf(_user),info.users[_user].collectTime);
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
        
        info.pools[7].dividends = info.pools[7].dividends.add(_poolAmount.mul(20).div(100));
        info.pools[15].dividends =  info.pools[15].dividends.add(_poolAmount.mul(30).div(100));
        info.pools[30].dividends=info.pools[30].dividends.add(_poolAmount.mul(50).div(100));
        
        emit Transfer(_from, info.dev, _devAmount);
        emit Transfer(_from, info.eater, _burnAmount);
        emit Transfer(_from, _to, _realAmount);
        
        emit Tax(_taxAmount);
        
        return _realAmount;
    }
    function _stake(uint256 _amount,uint256 day) internal {
      
        require(day==7||day==15||day==30,"product daytype not support");
		require(balanceOf(msg.sender) >= _amount);
		require(info.users[msg.sender].pools[day].staked.add(_amount) >= MIN_STAKE_AMOUNT);
		

		info.users[msg.sender].pools[day].unstakeTime = now + day*86400;
		info.pools[day].totalStaked =info.pools[day].totalStaked.add(_amount);
		info.users[msg.sender].pools[day].staked = info.users[msg.sender].pools[day].staked.add(_amount);

		emit Transfer(msg.sender, address(this), _amount);
		emit Stake(msg.sender, _amount,day);
	}
	function _unstake(uint256 _amount,uint256 day) internal {
	   	require(day==7||day==15||day==30,"product daytype not support");
	    require(info.users[msg.sender].pools[day].unstakeTime < now,"unstakeTime not arrive");
		require(info.users[msg.sender].pools[day].staked >= _amount);
		
		info.pools[day].totalStaked =info.pools[day].totalStaked.sub(_amount);
		info.users[msg.sender].pools[day].staked =	info.users[msg.sender].pools[day].staked.sub(_amount);
		
		emit Unstake(msg.sender, _amount,day);
	}
}