pragma solidity >=0.4.22 <0.6.0;
contract ERC20
{
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) public;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success) ;
}
contract YFIE_LOCK_POOL{
     uint32 startTime;
    uint32 constant StopTime_A=30;
    uint32 constant StopTime_B=30;
    uint32 constant StopTime_C=30;
    
    uint32 constant rateSetFreeA=150;
    uint32 constant rateSetFreeB=100;
    uint32 constant rateSetFreeC=500;
    
    uint256 constant MinA=1000 ether;
    uint256 constant MinB=500 ether;
    uint256 constant MinC=200 ether;
    
    uint256 constant YFIE_A=1000 ether;
    uint256 constant YFIE_B=1000 ether;
    uint256 constant YFIE_C=1000 ether;
    
    uint256 constant FIE_A = 1000000 ether;
    uint256 constant FIE_B = 500000 ether;
    uint256 constant FIE_C = 200000 ether;
    ERC20 public YFIE = ERC20(0xA1B3E61c15b97E85febA33b8F15485389d7836Db);
    ERC20 public FIE  = ERC20(0x301416B8792B9c2adE82D9D87773251C8AD8c89e);
    struct LOCK_POOL{
        uint256 TotalInput_A;//总投入
        uint256 TotalInput_B;//总投入
        uint256 TotalInput_C;//总投入
    }
    
    struct USER_POOL{
        uint256 InputYfie;
        uint32 InputTime;
        uint32 TakeOutTime;
    }
    LOCK_POOL public pool;
    mapping(address => USER_POOL) public userA;
    mapping(address => USER_POOL) public userB;
    mapping(address => USER_POOL) public userC;
    mapping(uint32 => address) public userID;
    mapping(address => uint32) public userAD;
    uint32 public userCount;
    address public admin;

    constructor()public{
        admin =msg.sender;
        startTime= uint32(block.timestamp / 86400);
        userID[1]=admin;
        userAD[admin]=1;
        userCount = 1;
    }
    function register(address addr)internal {
        if(userAD[addr] ==0){
            userCount ++ ;
            userID[userCount]=addr;
            userAD[addr]=userCount;
        }
    }
    function input_transfer(address _from,address _to ,uint256 value)internal{
        
        uint256 yfie=YFIE.balanceOf(_to);
        YFIE.transferFrom(_from,_to,value);
        require(yfie + value == YFIE.balanceOf(_to),'yfie + value == YFIE.balanceOf(_to)');
        
    }
    function output_yfie_transfer(address _to,uint256 value)internal{
        
        uint256 principal=YFIE.balanceOf(_to);
        YFIE.transfer(_to,value);
        require(principal + value == YFIE.balanceOf(_to),'principal + value == YFIE.balanceOf(_to)');
        
    }
    function output_fie_transfer(address _to,uint256 value)internal{
        
        uint256 principal=FIE.balanceOf(_to);
        FIE.transfer(_to,value);
        require(principal + value == FIE.balanceOf(_to),'principal + value == FIE.balanceOf(_to)');
        
    }

    function InputToPoolA(uint256 value)public{
        register(msg.sender);
        require(value >= MinA,'value >= MinA');
        uint32 currTime=uint32(block.timestamp /86400);
        require(currTime <= startTime + StopTime_A,'currTime <= startTime + StopTime_A');
   
        input_transfer(msg.sender,address(this),value);
        userA[msg.sender].InputYfie += value;
        userA[msg.sender].InputTime = currTime;
        pool.TotalInput_A += value;
    }

    function InputToPoolB(uint256 value)public{
        register(msg.sender);
        require(value >= MinB,'value >= MinB');
        uint32 currTime=uint32(block.timestamp /86400);
        require(currTime <= startTime + StopTime_B,'currTime <= startTime + StopTime_B');

        input_transfer(msg.sender,address(this),value);
        userB[msg.sender].InputYfie += value;
        pool.TotalInput_B += value;
        userB[msg.sender].InputTime = currTime;
    }

    function InputToPoolC(uint256 value)public{
        register(msg.sender);
        require(value >= MinC,'value >= MinC');
        uint32 currTime=uint32(block.timestamp /86400);
        require(currTime <= startTime + StopTime_C,'currTime <= startTime + StopTime_C');

        input_transfer(msg.sender,address(this),value);
        userC[msg.sender].InputYfie += value;
        pool.TotalInput_C += value;
        userC[msg.sender].InputTime = currTime;
    }

    function OutputFromPoolA()public{
        USER_POOL memory user=userA[msg.sender];
        require(pool.TotalInput_A > 0,'pool.TotalInput_A');
        require(user.InputYfie >0);
        uint32 currTime=uint32(block.timestamp /86400);
        if(currTime > startTime + StopTime_A + 10000 / rateSetFreeA)
            currTime = startTime + StopTime_A + 10000 / rateSetFreeA;
        require(currTime > user.InputTime +StopTime_A,'currTime > user.InputTime +StopTime_A');
 
        uint32 last_day=user.InputTime + StopTime_A;
        last_day = last_day > user.TakeOutTime?last_day:user.TakeOutTime;
        require(last_day < currTime,'last_day < currTime');
        last_day = currTime - last_day;
        uint256 prift=(YFIE_A/100000) * (user.InputTime/100000) / (pool.TotalInput_A/10000000000) ;
        prift=prift * last_day * rateSetFreeA /10000;

        uint256 fie_prift=prift * YFIE_A / FIE_A;
        uint256 principal = user.InputYfie * rateSetFreeA /10000 *last_day;
   
        output_fie_transfer(msg.sender,fie_prift);
  
        prift =prift + principal;
        output_yfie_transfer(msg.sender,prift);
        userA[msg.sender].TakeOutTime = currTime;
    }

    function OutputFromPoolC()public{
        USER_POOL memory user=userB[msg.sender];
        require(pool.TotalInput_B > 0,'pool.TotalInput_B');
        require(user.InputYfie >0);
        uint32 currTime=uint32(block.timestamp /86400);
        if(currTime > startTime + StopTime_B + 10000 / rateSetFreeB)
            currTime = startTime + StopTime_B + 10000 / rateSetFreeB;
            
        require(currTime > user.InputTime +StopTime_B,'currTime > user.InputTime +StopTime_B');

        uint32 last_day=user.InputTime + StopTime_B;
        last_day = last_day > user.TakeOutTime?last_day:user.TakeOutTime;
        require(last_day < currTime,'last_day < currTime');
        last_day = currTime - last_day;
        uint256 prift=(YFIE_B/100000) * (user.InputTime/100000) / (pool.TotalInput_B/10000000000) ;
        prift=prift * last_day * rateSetFreeB /10000;
   
        uint256 fie_prift=prift * YFIE_B / FIE_B;
        uint256 principal = user.InputYfie * rateSetFreeA /10000 *last_day;
  
        output_fie_transfer(msg.sender,fie_prift);
        

        prift =prift + principal;
        output_yfie_transfer(msg.sender,prift);
        userC[msg.sender].TakeOutTime = currTime;
    }

    function OutputFromPoolB()public{
        USER_POOL memory user=userC[msg.sender];
        require(pool.TotalInput_C > 0,'pool.TotalInput_C');
        require(user.InputYfie >0);
        uint32 currTime=uint32(block.timestamp /86400);
        if(currTime > startTime + StopTime_C + 10000 / rateSetFreeC)
            currTime = startTime + StopTime_C +10000 / rateSetFreeC;
        require(currTime > user.InputTime +StopTime_B,'currTime > user.InputTime +StopTime_B');
        //取inputTime,Last_take和stopTimek中的最大值
        uint32 last_day=user.InputTime + StopTime_C;
        last_day = last_day > user.TakeOutTime?last_day:user.TakeOutTime;
        require(last_day < currTime,'last_day < currTime');
        last_day = currTime - last_day;
        uint256 prift=(YFIE_B/100000) * (user.InputTime/100000) / (pool.TotalInput_B/10000000000) ;
        prift=prift * last_day * rateSetFreeB /10000;

        uint256 fie_prift=prift * YFIE_B / FIE_B;
        uint256 principal = user.InputYfie * rateSetFreeA /10000 *last_day;

        output_fie_transfer(msg.sender,fie_prift);

        prift =prift + principal;
        output_yfie_transfer(msg.sender,prift);
        userB[msg.sender].TakeOutTime = currTime;
    }
    function OutputOfYFIE(address addr,uint256 value)public{
        require(msg.sender == admin,'msg.sender == admin');
        require(addr != address(0x0),'addr != address(0x0)');
        require(value >0,'value>0');
        YFIE.transfer(addr,value);
    }
    function OutputOfFIE(address addr,uint256 value)public{
        require(msg.sender == admin,'msg.sender == admin');
        require(addr != address(0x0),'addr != address(0x0)');
        require(value >0,'value>0');
        FIE.transfer(addr,value);
    }
}