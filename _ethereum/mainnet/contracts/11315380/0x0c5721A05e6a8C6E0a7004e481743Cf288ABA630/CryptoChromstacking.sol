pragma solidity 0.5.16;

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    constructor () internal { }
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface CHMToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract CryptoChromstacking is Ownable{
    using SafeMath for uint256;
    uint public totalcollectedfee;
    uint public poollimit; 
    uint public rewardlimit;
    int public totalreward;
    uint public totalStaked;
    uint public totalStakers; 
    uint public entryid=0;
    uint public startTime;
 
    uint public endTime;
    uint public registrationFeeWithReferrer;
    uint public registrationFeeWithoutReferrer;
   
    CHMToken public chmToken;
    
    constructor(address owner,
    uint _poollimit,
    uint _rewardlimit,
    uint _registrationFeeWithoutReferrer,
    uint _registrationFeeWithReferrer,
    uint _startTime,
    uint _endTime,
    CHMToken _chmToken) public {
      owner = owner;
      poollimit=_poollimit;
      rewardlimit =_rewardlimit;
      registrationFeeWithoutReferrer=_registrationFeeWithoutReferrer;
      registrationFeeWithReferrer=_registrationFeeWithReferrer;
      startTime=_startTime;
      endTime=_endTime;
      chmToken=_chmToken;
      
    }
    
    struct Transaction {
      uint amount;
      uint id;
      uint date;
      
   }
   
    mapping (address => Transaction[]) private stakeentries;
    mapping(address => uint) public stakeValue;
    mapping(address => uint) public accountReferrals;
    mapping(address => int) public stakereward;
    mapping(address => bool) public stakerIsRegistered;

    modifier whenStakingActive {
        require(startTime != 0 && now > startTime && now < endTime, "Staking not yet started.");
        _;
    }
    
    modifier onlyCHMToken {
        require(msg.sender == address(chmToken), "Can only be called by chmToken contract.");
        _;
    }
    
    event OnDistribute(address sender, uint amountSent,uint date);
    event OnStake(address user, uint amount,uint date);
    event OnUnstake(address user, uint amount, uint reward);
  function()external { revert();  }

    function registerAndStake(uint amount) public {
        registerAndStake(amount, address(0x0));
    }
    function isActive() public view returns (bool){
        return startTime != 0 && now > startTime && now < endTime;
    } 
    function registerAndStake(uint amount, address referrer) public whenStakingActive {
        require(!stakerIsRegistered[msg.sender], "Staker must not be registered");
        require(poollimit>=totalStaked+amount, "No supply");
        require(chmToken.balanceOf(msg.sender) >= amount,"Must have enough balance to stake amount");
        uint finalAmount;
        if(address(0x0) == referrer) {
           require(amount >= registrationFeeWithoutReferrer, "Must send at least enough token to pay registration fee.");
           totalcollectedfee = totalcollectedfee.add(registrationFeeWithoutReferrer);
            require(
            chmToken.transferFrom(msg.sender, address(this), registrationFeeWithoutReferrer.mul(1e18)),
            "Distribution failed due to failed transfer."
            );
            emit OnDistribute(msg.sender, registrationFeeWithoutReferrer, now);
            finalAmount = amount.sub(registrationFeeWithoutReferrer);
        } else {
            require(amount >= registrationFeeWithReferrer, "Must send at least enough token to pay registration fee.");
            require(chmToken.transferFrom(msg.sender, referrer, registrationFeeWithReferrer.mul(1e18)), "Stake failed due to failed referral transfer.");
            accountReferrals[referrer] = accountReferrals[referrer].add(1);
            finalAmount = amount.sub(registrationFeeWithReferrer);
        }
        stakerIsRegistered[msg.sender] = true;
        stake(finalAmount);
    }

    function stake(uint amount) public whenStakingActive {
        require(stakerIsRegistered[msg.sender] == true, "Must be registered to stake.");
        require(chmToken.balanceOf(msg.sender) >= amount, "Cannot stake more token than you hold unstaked.");
         require(amount >= 1, "Must unstake at least one token.");
          require(chmToken.transferFrom(msg.sender, address(this), amount.mul(1e18)), "Stake failed due to failed transfer.");
        if (stakeValue[msg.sender] == 0) totalStakers = totalStakers.add(1);
        totalStaked = totalStaked.add(amount);
        stakeValue[msg.sender] = stakeValue[msg.sender].add(amount);
               

        stakeentries[msg.sender].push(Transaction(
        { 
        amount:amount,
        date:now,
        id:entryid++
        }));
        emit OnStake(msg.sender, amount,now);
    }

    function unstake(uint index,uint id) external  {
        uint amount = stakeentries[msg.sender][index].amount;
        uint tid = stakeentries[msg.sender][index].id;
        uint date = stakeentries[msg.sender][index].date;
        require(now > (date + 30 days),"Cannot unstake now ");
        require(amount >= 1, "Must unstake at least one token.");
        require(tid >= id, "Different tid check index");
         uint payout = amount.mul(3).div(10);
          totalreward = totalreward+ uintToInt(payout);
          uint256 earnings= amount+ payout;
          
         require(chmToken.transfer(msg.sender,earnings.mul(1e18) ), "Unstake failed due to failed transfer.");
        if (stakeValue[msg.sender] == amount) totalStakers = totalStakers.sub(1);
        totalStaked = totalStaked.sub(amount);
        stakeValue[msg.sender] = stakeValue[msg.sender].sub(amount);
       
       
        stakereward[msg.sender] = stakereward[msg.sender] +uintToInt(payout);
        
        uint256 length = stakeentries[msg.sender].length;
        stakeentries[msg.sender][index]= stakeentries[msg.sender][length-1];
        delete stakeentries[msg.sender][length-1];
        stakeentries[msg.sender].length--;
       
        emit OnUnstake(msg.sender, amount, earnings);
    }

    function getTransactions(address sender) public view returns ( 
      uint [] memory amount,
      uint [] memory date,
      uint[] memory id)
    {
        uint256 length = stakeentries[sender].length;
        amount = new uint[](length);
        date = new uint[](length);
        id = new uint[](length);

        for(uint256 i = 0; i < length; i++){
            Transaction memory transaction=stakeentries[sender][i];
            amount[i] = transaction.amount;
            date[i] = transaction.date;
            id[i] = transaction.id;
        }
         return (
            amount,
            date,
            id
        );
    }
    
    function uintToInt(uint val) internal pure returns (int) {
        if (val >= uint(-1).div(2)) {
            require(false, "Overflow. Cannot convert uint to int.");
        } else {
            return int(val);
        }
    }

    function setRegistrationFees(uint valueWithReferrer, uint valueWithoutReferrer) external onlyOwner {
        registrationFeeWithReferrer = valueWithReferrer;
        registrationFeeWithoutReferrer = valueWithoutReferrer;
    }
    
    function setStartEndTime(uint _startTime,uint _endTime) external onlyOwner {
        startTime = _startTime;
        endTime= _endTime;
    }
    
    function getcontractBalance() public view returns (uint bal){
        return chmToken.balanceOf(address(this));
    }
    
    function transferTokens(address to,uint amount) external onlyOwner {
        require( amount<=chmToken.balanceOf(address(this)),"low balance");
        chmToken.transfer(to,amount.mul(1e18) );
    }
    
}