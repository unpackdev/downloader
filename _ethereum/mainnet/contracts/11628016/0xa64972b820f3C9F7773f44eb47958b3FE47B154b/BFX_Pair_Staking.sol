pragma solidity ^0.5.4;

contract BFX_Pair_Staking {

    using SafeMath for uint256;
    
    address public PairAddress          = address(0x917909fA34af61868687F57D61344Fb600E064D5);
    address public bfxContractAddress   = address(0x25901F2a5A4bb0aaAbe2CDb24E0E15A0d49B015d);
    address public BFX_reward_holder    = address(0x46E74d30e381684a21e392Fc55251FB6cEaFf4A1); 
    ERC20Contract token;
    ERC20Contract pair;
    
    address payable _owner;
    
    uint public BFX_PAIR_Reward_Ratio = 1000;      //1 PAIR = 10.00 BFX per block
    
    uint public totalInvested = 0;
    uint public totalInterest = 0;
    
    mapping(address => uint256) public investment;
    mapping(address => uint256) public interest;
    mapping(address => uint256) public lastInterestTime;
    mapping(address => uint256) public totalearnedInterest;
    
    event stakeEvent(address _address,uint256 Amount);
    event unstakeEvent(address _address,uint256 Amount);
    event withdrawInterestEvent(address _address,uint256 Amount);
    
    constructor () public //creation settings
    {
        _owner              = msg.sender;
        token               = ERC20Contract(bfxContractAddress);
        pair                = ERC20Contract(PairAddress);
 
    }
    
    function stake(uint256 amount) public {
        require(amount>=0,'zero amount');
        
        //Check if the contract is allowed to send token on user behalf
        uint256 allowance = pair.allowance(msg.sender,address(this));
        require (allowance>=amount,'allowance error');

        require(pair.transferFrom(msg.sender,address(this),amount),'transfer Token Error');
        
        if (lastInterestTime[msg.sender] == 0)
            lastInterestTime[msg.sender] = block.number;
        else{
            interest[msg.sender] = interest[msg.sender].add(calculateInterest(msg.sender));
            lastInterestTime[msg.sender] = block.number;
        }
            
        investment[msg.sender] = investment[msg.sender].add(amount);
        totalInvested = totalInvested.add(amount);
        emit stakeEvent(msg.sender,amount);
    }
    function Unstake(uint256 amount) public {
        require(lastInterestTime[msg.sender]!=0);
        require(lastInterestTime[msg.sender]<=block.number);
        require(amount<=investment[msg.sender],'not enough fund');
        
        //accumulate current Interest and set new time
        interest[msg.sender] = interest[msg.sender].add(calculateInterest(msg.sender));
        lastInterestTime[msg.sender] = block.number;
        
        investment[msg.sender] = investment[msg.sender].sub(amount);
        totalInvested = totalInvested.sub(amount);
        
        require(pair.transfer(msg.sender, amount),'transfer Token Error');
        emit unstakeEvent(msg.sender,amount);
    }
    function claimRewards() public {
        require(lastInterestTime[msg.sender]!=0);
        require(lastInterestTime[msg.sender]<block.number);
        uint256 currentInterest = calculateInterest(msg.sender);
        lastInterestTime[msg.sender] = block.number;
        uint256 toPayReward = interest[msg.sender]+currentInterest;
        interest[msg.sender] = 0;
        
        require(token.transferFrom(BFX_reward_holder,msg.sender, toPayReward),'transfer Token Error');
        
        emit withdrawInterestEvent(msg.sender,toPayReward);
        totalInterest = totalInterest.add(toPayReward);
        totalearnedInterest[msg.sender] = totalearnedInterest[msg.sender].add(toPayReward);
        
    }
    //interest from last withdrawTime
    function calculateInterest(address account) public view returns(uint256){
        if (lastInterestTime[account]==0) return 0;
        if (lastInterestTime[account]>=block.number) return 0;
        uint256 stakingDuration = block.number.sub(lastInterestTime[account]);  //in seconds
        
        return investment[account].mul(BFX_PAIR_Reward_Ratio.mul(stakingDuration).div(100));
        
    }
    function getContractBalance() public view returns(uint256 _contractBalance) {
        return pair.balanceOf(address(this));
    }
    //Setters
    
    function setBFXaddress(address _newAddress) public onlyOwner() {
        bfxContractAddress = _newAddress;
        token              = ERC20Contract(bfxContractAddress);
    }
    function setPairAddress(address _newPairAddress) public onlyOwner() {
        PairAddress         = _newPairAddress;
        pair                = ERC20Contract(PairAddress);
    }
    function setBFX_ETH_Reward(uint _newBFX_PAIR_Reward_Ratio) public onlyOwner() {
        BFX_PAIR_Reward_Ratio = _newBFX_PAIR_Reward_Ratio;
    }
    function setBFX_Reward_Holder(address _newHolder) public onlyOwner() {
        BFX_reward_holder = _newHolder;
    }
    
    
    modifier onlyOwner(){
        require(msg.sender==_owner,'Not Owner');
        _;
    }
    function getOwner() public view returns(address ) {
        return _owner;
    }
    //Protect the pool in case of hacking
    function kill() onlyOwner public {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_owner, balance);
        pair.transfer(_owner, balance);
        selfdestruct(_owner);
    }
    function transferFundBFX(uint256 amount) onlyOwner public {
        uint256 balance = token.balanceOf(address(this));
        require(amount<=balance,'exceed contract balance');
        token.transfer(_owner, amount);
    }
    function transferFundPair(uint256 amount) onlyOwner public {
        uint256 balance = pair.balanceOf(address(this));
        require(amount<=balance,'exceed contract balance');
        pair.transfer(_owner, amount);
    }
    function transferOwnership(address payable _newOwner) onlyOwner external {
        require(_newOwner != address(0) && _newOwner != _owner);
        _owner = _newOwner;
    }
}


contract ERC20Contract
{
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
}
// ----------------------------------------------------------------------------

// Safe maths

// ----------------------------------------------------------------------------

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {

        c = a + b;

        require(c >= a);

    }

    function sub(uint a, uint b) internal pure returns (uint c) {

        require(b <= a);

        c = a - b;

    }

    function mul(uint a, uint b) internal pure returns (uint c) {

        c = a * b;

        require(a == 0 || c / a == b);

    }

    function div(uint a, uint b) internal pure returns (uint c) {

        require(b > 0);

        c = a / b;

    }

}