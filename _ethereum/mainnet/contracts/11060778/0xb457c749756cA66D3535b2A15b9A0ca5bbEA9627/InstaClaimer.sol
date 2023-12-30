/* 
 *  MultitokenPeriodicStaker
 *  VERSION: 1.0
 *
 */

contract ERC20{
    function allowance(address owner, address spender) external view returns (uint256){}
    function transfer(address recipient, uint256 amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){}
    function balanceOf(address account) external view returns (uint256){}
}

contract PeriodicStaker {
    
    event Staked(address staker);

    uint public total_stake=0;
    uint public total_stakers=0;
    mapping(address => uint)public stake;
    
    uint public status=0;
    
    uint safeWindow=40320;
    
    uint public startLock;
    uint public lockTime;
    uint minLock=10000;
    uint maxLock=200000;
    
    uint public freezeTime;
    uint minFreeze=10000;
    uint maxFreeze=200000;

    address public master;
    mapping(address => bool)public modules;
    address[] public modules_list;
    

    constructor(address mastr) public {
        master=mastr;
    }
    

    function stakeNow(address tkn,uint256 amount) public returns(bool){
        require(stk(tkn,amount,msg.sender));
        return true;
    }
    
    
    function stakeNow(address tkn,uint amount,address staker) public returns(bool){
        require(modules[msg.sender]);
        require(stk(tkn,amount,staker));
        return true;
    }
    
    function stk(address tkn,uint amount,address staker)internal returns(bool){
        require(amount > 0);
        require(status!=2);
        ERC20 token=ERC20(tkn);
        uint256 allowance = token.allowance(staker, address(this));
        require(allowance >= amount);
        require(token.transferFrom(staker, address(this), amount));
        if(stake[staker]==0)total_stakers++;
        stake[staker]+=amount;
        total_stake+=amount;
        emit Staked(staker);
        return true;
    }
    
    function unstake(address tkn) public returns(bool){
        require(unstk(tkn,msg.sender));
        return true;
    }
    
    function unstake(address tkn,address unstaker) public returns(bool){
        require(modules[msg.sender]);
        require(unstk(tkn,unstaker));
        return true;
    }
    
    function unstk(address tkn,address unstaker)internal returns(bool){
        require(stake[unstaker] > 0);
        if(status==1)require((startLock+lockTime)<block.number);
        ERC20 token=ERC20(tkn);
        require(token.transfer(unstaker, stake[unstaker]));
        total_stake-=stake[unstaker];
        stake[unstaker]=0;
        total_stakers--;
        return true;
    }
    
    function openDropping(uint lock) public returns(bool){
        require(msg.sender==master);
        require(block.number>startLock+safeWindow);
        require(minLock<=lock);
        require(lock<=maxLock);
        require(status==0);
        status=1;
        lockTime=lock;
        startLock=block.number;
        return true;
    }
    
    function freeze(uint freez) public returns(bool){
        require(msg.sender==master);
        require(block.number>startLock+safeWindow);
        require(minFreeze<=freez);
        require(freez<=maxFreeze);
        require(status==0);
        status=2;
        freezeTime=freez;
        startLock=block.number;
        return true;
    }
    
    function open() public returns(bool){
        require(status>0);
        if(status==1)require(block.number>startLock+lockTime);
        if(status==2)require(block.number>startLock+freezeTime);
        startLock=block.number;
        status=0;
        return true;
    }
    
    function setMaster(address new_master)public returns(bool){
        require(msg.sender==master);
        master=new_master;
        return true;
    }
    
    function setModule(address new_module,bool set)public returns(bool){
        require(msg.sender==master);
        modules[new_module]=set;
        if(set)modules_list.push(new_module);
        return true;
    }
    

}

contract ItemsGifterDB{
    
    event Gifted(address gifted);
    
    address[] public modules_list;
    mapping(address => bool)public modules;
    
    ERC20 public token;
    address master;
    address public receiver;
    
    constructor() public{
        master=msg.sender;
    }
    
    function gift(address tkn,uint amount,address gifted) public returns(bool){
        require(modules[msg.sender]);
        ERC20 token=ERC20(tkn);
        require(token.transfer(gifted, amount));
        emit Gifted(gifted);
        return true;
    } 
    
    function burn(address tkn)public returns(bool){
        require(msg.sender==master);
        ERC20 token=ERC20(tkn);
        token.transfer(master, token.balanceOf(address(this)));
    }
    
    function setModule(address new_module,bool set)public returns(bool){
        require(msg.sender==master);
        modules[new_module]=set;
        if(set)modules_list.push(new_module);
        return true;
    }
    
    function setMaster(address new_master)public returns(bool){
        require(msg.sender==master);
        master=new_master;
        return true;
    }
    
}

contract LockDropper{
    
    PeriodicStaker public staker;
    ItemsGifterDB public gifter;
    uint public multiplier;
    
    constructor() public{
        staker=PeriodicStaker(0x7d410AFA45377006A0F79Ae6157A6A873Bfa5567);
        gifter=ItemsGifterDB(0xC9746af16e5d5cc414eDF53f91cBA76e6Eaf739D);
        multiplier=30;
    }
    
    function LockDrop(uint amount) public returns(bool){
        require(staker.status()==1);
        require(staker.stakeNow(0x801F90f81786dC72B4b9d51Ab613fbe99e5E4cCD,amount,msg.sender));
        require(gifter.gift(0x801F90f81786dC72B4b9d51Ab613fbe99e5E4cCD,amount*multiplier/100,msg.sender));
        return true;
    } 
    

    
}

contract BerryClaimer{
    
    PeriodicStaker public staker;
    ItemsGifterDB public gifter;
    address berry;
    
    constructor() public{
        staker=PeriodicStaker(0x7d410AFA45377006A0F79Ae6157A6A873Bfa5567);
        gifter=ItemsGifterDB(0xC9746af16e5d5cc414eDF53f91cBA76e6Eaf739D);
        berry=0xC9746af16e5d5cc414eDF53f91cBA76e6Eaf739D;
    }
    
    function claimBerry() public returns(bool){
        require(staker.stake(msg.sender)>0);
        require(gifter.gift(berry,1,msg.sender));
        return true;
    } 
    
    
}


contract InstaClaimer{
    
    PeriodicStaker public staker;
    uint public tot;
    mapping(address => bool) rewarded;
    
    constructor() public{
        staker=PeriodicStaker(0x7d410AFA45377006A0F79Ae6157A6A873Bfa5567);
        tot=staker.total_stake();
    }
    
 
    function instaClaim() public returns(bool){
        require(staker.status()==2);
        uint s=staker.stake(msg.sender);
        require(s>0);
        require(!rewarded[msg.sender]);
        rewarded[msg.sender]=true;
        require(ERC20(0x801F90f81786dC72B4b9d51Ab613fbe99e5E4cCD).transfer(msg.sender, 30000000000000000000/(tot*1000/s)*1000));
        return true;
    } 
    
}