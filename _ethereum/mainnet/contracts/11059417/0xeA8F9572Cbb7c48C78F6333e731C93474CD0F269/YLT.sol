pragma solidity ^0.6.0;

library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(a >= b);
		return a - b;
	}
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a / b;
		return c;
	}
}

contract YLT {
	string public name = "Yun Lian Token";
	string public symbol = "YLT";
	uint256 public decimals = 8;
	uint256 private constant _totalSupply = 100000000 * 10**8;

	address payable private _owner;
	uint256 public _ratePerEth = 10000000; 	// Number of tokens per Ether 1ETH 	 	 1000YLT
	uint256 public _ratePerYLT = 8000000;  	// Number of tokens per 	  1000YLT	 0.8ETH
	uint256 public _raisedAmount = 0;


	struct Record {
        uint256[] eth;  	// 存入eth
        uint256[] ylt;		// 兑换的ylt
    }
	mapping(address => Record) private _deposits;
	mapping(address => Record) private _withdraws;


	// 该地址上的代币余额
	mapping(address => uint256) private _balances;
	// 配额
	mapping (address => mapping (address => uint256)) private _allowances;
	using SafeMath for uint256;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	constructor() public {
		_owner = msg.sender;
	}
	
	modifier onlyOwner() {
    	require(_owner == msg.sender);
   	 	_;
   	}
   	function setRateEth(uint256 ratePerEth) public onlyOwner {
   		_ratePerEth = ratePerEth;
   	}
   	function setRateYLT(uint256 ratePerYLT) public onlyOwner {
		_ratePerYLT = ratePerYLT;
   	}
   	function destroy() public onlyOwner{
   		// 合约自我删除，合约账户中剩余的以太币发到_owner地址
   		selfdestruct(_owner);
   	}

   	receive () external payable{
    	uint256 tokenAmount = msg.value.div(_ratePerEth);	// 可兑换代币数量

    	_raisedAmount = _raisedAmount.add(tokenAmount);
    	require(_raisedAmount <= _totalSupply);				// 已兑换代币数量必须小于总值

   		_balances[msg.sender] = _balances[msg.sender].add(tokenAmount);	// 增加该账户代币数量

		_deposits[msg.sender].eth.push(msg.value);
		_deposits[msg.sender].ylt.push(tokenAmount);

   		emit Transfer(address(this), msg.sender, tokenAmount);		// log event onto the blockchain
   	}

   	// YLT 兑换 eth
   	function withdraw(uint256 amount) public{
   		// 账户代币余额减少，总兑换代币数量减少
   		_balances[msg.sender] = _balances[msg.sender].sub(amount);
   		_raisedAmount = _raisedAmount.sub(amount);

   		// 计算 YLT 兑换为 eth的数量，转eth到账户地址上
   		uint256 ethAmount = amount.mul(_ratePerYLT);

		_withdraws[msg.sender].eth.push(ethAmount);
		_withdraws[msg.sender].ylt.push(amount);

   		msg.sender.transfer(ethAmount);
   	}

   	function getRecord() public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory){
   	    return (_deposits[msg.sender].eth, _deposits[msg.sender].ylt, _withdraws[msg.sender].eth, _withdraws[msg.sender].ylt);
   	}

	function totalSupply() public pure returns (uint256) {
        return _totalSupply;
    }

	function balanceOf(address account) public view returns (uint256) {
		return _balances[account];
	}

	function transfer(address recipient, uint256 amount) public returns (bool) {
		_balances[msg.sender] = _balances[msg.sender].sub(amount);
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(msg.sender, recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public returns (bool) {
		// 只允许: 清零配额，初始化配额
		require((amount == 0 ) || (_allowances[msg.sender][spender] == 0));
		_allowances[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}
	// 增加配额
	function increaseAllowance(address spender, uint256 addAmount) public returns (bool){
		_allowances[msg.sender][spender] = _allowances[msg.sender][spender].add(addAmount);
		emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
		return true;
	}
	// 减少配额
	function decreaseAllowance(address spender, uint256 subAmount) public returns(bool) {
		uint256 oldAmount = _allowances[msg.sender][spender];
		if (subAmount > oldAmount) {
			_allowances[msg.sender][spender] = 0;
		} else {
			_allowances[msg.sender][spender] = oldAmount.sub(subAmount);
		}
		emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
		// 配额减少
		_allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);

		// sender代币减少, recipient代币增加
		_balances[sender] = _balances[sender].sub(amount);
		_balances[recipient] = _balances[recipient].add(amount);
		
		emit Transfer(sender, recipient, amount);
		return true;
	}
}