// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c=a+b;
        require(c>=a,"addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b<=a,"subtraction overflow");
        uint256 c=a-b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a==0) return 0;
        uint256 c=a*b;
        require(c/a==b,"multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b>0,"division by zero");
        uint256 c=a/b;
        return c;
    }
}

contract Owned {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    address payable owner;
    address payable newOwner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract ERC20 {
    using SafeMath for uint256;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function balanceOf(address _owner) public view returns (uint256 balance) {return balances[_owner];}

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require (balances[msg.sender]>=_amount&&_amount>0);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }

    function transferFrom(address _from,address _to,uint256 _amount) public returns (bool success) {
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to]  = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

contract KryptonStakeToken is Owned,ERC20{
    using SafeMath for uint256;
    uint8 public profit;
    uint8[5] public mlm;
    uint8 public fee;
    struct Deposit {
        address payable ref;
        uint paid;
    }
    mapping (address=>Deposit) deposits;
    event Mint(address indexed _from, uint256 _value);
    event Profit(address indexed _to, uint256 _value);
    
    constructor() {
        symbol = "CRYPT";
        name = "Krypton Stake Token";
        decimals = 18;
        profit = 36;
        fee = 1;
        mlm = [9,6,3,1,1];
        totalSupply = 0;
        owner = msg.sender;
    }
    
    receive() external payable {
        revert();
    }
    
    function buyToken(address payable ref) public payable returns (bool) {
        require(msg.value>0);
        if (ref==address(0)||ref==msg.sender||ref==address(this)) ref = owner;
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        totalSupply = totalSupply.add(msg.value);
        deposits[msg.sender].ref = ref;
        deposits[msg.sender].paid = block.timestamp;
        uint256 _bonus = (msg.value.mul(mlm[0])).div(100);
        balances[ref] = balances[ref].add(_bonus);
        totalSupply = totalSupply.add(_bonus);
        uint256 _fee = (msg.value.mul(fee)).div(100);
        balances[owner] = balances[owner].add(_fee);
        totalSupply = totalSupply.add(_fee);
        emit Mint(msg.sender,msg.value);
        return true;
    }
    
    function calcProfit(address _user) public view returns(uint16 _period,uint256 _profit){
        if (balances[_user]==0) return (0,0);
        _period = uint16((block.timestamp-deposits[_user].paid)/86400);
        _profit = uint256((balances[_user].mul(_period)).mul(profit)).div(36500);
        return (_period,_profit);
    }
    
    function getProfit() public payable returns (uint256 _value){
        require(balances[msg.sender]>0,"emptydeposit");
        (uint16 _period,uint256 _profit) = calcProfit(msg.sender);
        require(_period>0&&_profit>0,"emptyprofit");
        _value = _profit;
        address ref = deposits[msg.sender].ref;
        uint levels = mlm.length;
        for(uint8 i=0;i<levels;i++){
            uint256 b = uint256(_profit*mlm[i]/100);
            if (b>0) {
                balances[ref] = balances[ref].add(b);
                totalSupply = totalSupply.add(b);
                _value = _value.sub(b);
            }
            ref = deposits[ref].ref;
            if (ref==owner) break;
        }
        require(address(this).balance>=_value);
        deposits[msg.sender].paid = block.timestamp;
        msg.sender.transfer(_value);
        emit Profit(msg.sender,_value);
        return _value;
    }
    
    function getDeposit(address _user) public view returns (address ref, uint paid){
        require(_user!=address(0),"wronguser");
        return (deposits[_user].ref,deposits[_user].paid);
    }
}