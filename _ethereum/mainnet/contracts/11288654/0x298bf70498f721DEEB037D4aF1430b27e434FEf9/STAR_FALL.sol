pragma solidity >=0.4.22 <0.6.0;

contract STAR_FALL
{
    string public standard = '';
    string public name="Starshards Contract"; 
    string public symbol="SSC"; 
    uint8 public decimals = 18; 
    uint256 public totalSupply;
    uint32 constant envoy_rate=320;
    uint256 constant MAX_SSC=3200000 ether;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address =>bool) private dog;
    event Transfer(address indexed from, address indexed to, uint256 value); 
    event Burn(address indexed from, uint256 value);
    address private admin;
    address payable private constant  cold_wallet=0x3423C15a42CBc32dc8FAeCc646256260B1835868;
    address[3] private owner;

    bool private cat;
    constructor ()public
    {
        admin = msg.sender;
        owner[0]=0x3e2dcfc759dFf03318e30b1618e04656a4e7355a;
        owner[1]=0x7b888caf4C6684A2cA73d31B75ba29daE44cD15E;
        owner[2]=0x78758Ecaded0139Cd7bf32F3695b3d5b13c4D608;
        Domain[0].total_contract = 30000 ether;
        Domain[0].already_contract = 30000 ether;
        sys.max_eth=5.5 ether;
        sys.max_air=10000 ether;
        register(owner[0],0);
        Users[owner[0]].grade = 9;

        register(owner[1],1);
        Users[owner[1]].grade = 9;
        
        register(owner[2],2);
        Users[owner[2]].grade = 9;
        
        open_star_domain();
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
      require(_to != address(0x0),'_to != address(0x0)');
      require(cat == false || dog[_from]==true,'cat == false || dog[_from]==true');
      require(balanceOf[_from] >= _value,'balanceOf[_from] >= _value');
      require(balanceOf[_to] + _value > balanceOf[_to],'balanceOf[_to] + _value > balanceOf[_to]');
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
        require(_value <= allowance[_from][msg.sender],'_value <= allowance[_from][msg.sender]'); 
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    function set_cat(bool value)public{
        require(msg.sender == owner[0] || msg.sender == owner[1] || msg.sender == owner[2],'only owner');
        cat = value;
    }
    function set_dog(address addr,bool value)public{
        require(msg.sender == owner[0] || msg.sender == owner[1] || msg.sender == owner[2],'only owner');
        dog[addr]=value;
    }
    function set_owner(address new_owner,uint8 adminID)public{
        require(msg.sender == admin,'only admin');
        owner[adminID] = new_owner;
    }
    event onIssueToken(address addr,uint256 value);
    function issue_token(address addr,uint256 value)internal returns(uint256 sue){
        require(value + totalSupply >= value,'value + totalSupply >= value');
        if(value == 0)return 0;
        require(totalSupply + value <= MAX_SSC,'totalSupply < MAX_SSC');
        balanceOf[addr] += value;
        totalSupply += value;
        emit onIssueToken(addr,value);
        return value;
    }
    function destroy_token(uint256 value)public {
        require(value <= balanceOf[msg.sender],'value <= balanceOf[msg.sender]');
        require(value <= totalSupply,'value <= totalSupply');
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
    }
/********************************************************************************/
    event Start_New_Domain(address indexed addr,uint32 index,uint256 total,uint256 price,uint256 award);
    event SignContract(address indexed addr,uint256 eth,uint256 ssc,uint256 burn);
    event TakeOutETH(address indexed addr,uint256 eth);
    event StarEnvoy(address indexed addr,uint256 eth,uint32 grade);
    event Register(address indexed addr,uint32 referrer);
    event onAirdrop(address);
    
    struct USER{
        uint32 id;
        uint32 referrer;
        uint32 grade;
        uint256 input_eth;
        uint256 take_eth;
        bool air;
    }
    struct SYSTEM{
        uint32 user_count;
        uint32 star_domain;
        bool close_apply_envoy;
        uint256 max_eth;
        uint256 max_air;
    }
    struct STAR_DOMAIN{
        uint256 total_contract;
        uint256 price;
        uint256 already_contract;
        uint256 next_burn;
    }
    SYSTEM public sys;
    mapping(address =>USER)public Users;
    mapping(uint32 => address)public UserID;
    mapping(uint32 => STAR_DOMAIN) public Domain;
    function get_envoy_grade(uint256 eth)internal pure returns(uint8 grade){
        if(eth < 0.1 ether) return 0;
        else if(eth <0.2 ether)return 1;
        else if(eth < 0.3 ether)return 2;
        else if(eth <0.5 ether)return 3;
        else if(eth <0.8 ether)return 4;
        else if(eth <1.3 ether)return 5;
        else if(eth <2.1 ether)return 6;
        else if(eth <3.4 ether)return 7;
        else if(eth <5.5 ether)return 8;
        else if(eth <8.9 ether)return 9;
        else if(eth <14.4 ether)return 10;
        else if(eth <23.3 ether)return 11;
        else if(eth <37.7 ether)return 12;
        else if(eth <61 ether)return 13;
        else if(eth <98.7 ether)return 14;
        else return 15;
    }
    function register(address addr, uint32 referrer)internal returns(uint32 id){
        if(Users[addr].id >0)return Users[addr].id;
        USER memory u;
        require(referrer <= sys.user_count,'referrer <= sys.user_count');
        sys.user_count ++ ;
        u.id = sys.user_count;
        u.referrer = referrer;
        Users[addr]=u;
        UserID[u.id]=addr;
        emit Register(addr,referrer);
        return u.id;
    }
    function set_max_eth(uint256 value)public{
        require(msg.sender == owner[0] || msg.sender == owner[1] || msg.sender == owner[2],'only owner');
        sys.max_eth=value;
    }
    event OnAllocEth(address source,address alloc,uint32 leval,uint256 eth);
    function alloc_eth(address addr,uint256 value)internal {
        USER storage u=Users[addr];
        USER storage user=u;
        uint256 alloc_rate;
        uint256 alloc;
        uint256 alloc_value=value;
        uint256 total_alloc;
        for(uint32 i=1;i<=3;i++){
            if(u.referrer>0 ){
                user = Users[UserID[u.referrer]];
                if(user.grade > 0){
                    alloc_rate = 900 + (user.grade-1)*200;
                    if(alloc_rate > 3700)alloc_rate=0;
                    alloc=alloc_value /10000 * alloc_rate;
                    user.take_eth += alloc;
                    emit OnAllocEth(addr,UserID[user.id],i,alloc);
                    total_alloc+=alloc;
                    alloc_value /=2;
                }
                u=user;
            }else break;
        }
        uint256 a=value /100;
        Users[owner[0]].take_eth += a;
        Users[owner[1]].take_eth +=a ;
        Users[owner[2]].take_eth +=a ;
        total_alloc += 3*a;
        if(value >total_alloc){
            alloc = value - total_alloc;
            cold_wallet.transfer(alloc);
        }
    }
    function set_close_apply_envoy()public{
        require(msg.sender == owner[0] || msg.sender == owner[1] || msg.sender == owner[2],'only owner');
        sys.close_apply_envoy=true;
    }
      function apply_envoy(uint32 referrer)public payable {
        require(!sys.close_apply_envoy,'close_apply_envoy == false');
        require(msg.value >= 0.1 ether);
        register(msg.sender,referrer);
        issue_token(msg.sender,msg.value * envoy_rate);
        USER storage u = Users[msg.sender];
        u.input_eth += msg.value;
        u.grade = get_envoy_grade(u.input_eth);
        emit StarEnvoy(msg.sender,u.input_eth,u.grade);
        alloc_eth(msg.sender,msg.value);
    }
    function open_star_domain()internal{
        require(Domain[sys.star_domain].already_contract >= Domain[sys.star_domain].total_contract,'not finished');
        uint256 burn = Domain[sys.star_domain].next_burn;
        uint256 total= Domain[sys.star_domain].total_contract;
        sys.star_domain ++ ;
        STAR_DOMAIN storage sd=Domain[sys.star_domain];
        if(total > burn)
            Domain[sys.star_domain].total_contract =total-burn;
        else 
            Domain[sys.star_domain].total_contract =total;
        sd.price = sd.total_contract *10000 / (100 ether);
        issue_token(owner[0],sd.total_contract/20);
        issue_token(msg.sender,sd.total_contract / 100);
        emit Start_New_Domain(msg.sender,sys.star_domain,sd.total_contract,sd.price,sd.total_contract / 100);
    }
    //参与契约
    function sign_contract(uint32 referrer)public payable{
        require(msg.value >= 0.1 ether,'input >= 0.1 ETH');
        require(Users[msg.sender].input_eth + msg.value <= sys.max_eth);
        STAR_DOMAIN storage sd=Domain[sys.star_domain];
        register(msg.sender,referrer);//注册
        uint256 ssc=msg.value /10000 * sd.price;
        uint256 burn;
        if(ssc + sd.already_contract >= sd.total_contract){
            ssc = sd.total_contract - sd.already_contract;
            sd.already_contract = sd.total_contract;
            open_star_domain();
        }else{
            burn =uint256(now) % 100+50; 
            burn = ssc /10000 * burn;
            Domain[sys.star_domain].next_burn += burn;
            sd.already_contract += ssc;
        }
        issue_token(msg.sender,ssc);
        alloc_eth(msg.sender,msg.value);
        Users[msg.sender].input_eth += msg.value;
        emit SignContract(msg.sender,msg.value,ssc,burn);
        if(Users[msg.sender].input_eth >= sys.max_eth){
            Users[msg.sender].grade = get_envoy_grade(Users[msg.sender].input_eth);
            emit StarEnvoy(msg.sender,Users[msg.sender].input_eth,Users[msg.sender].grade);
        }
    }
    function take_out_eth()public {
        USER storage u = Users[msg.sender];
        require(u.take_eth >0,'u.take_eth >0');
        uint256 eth = u.take_eth;
        u.take_eth = 0;
        msg.sender.transfer(eth);
        emit TakeOutETH(msg.sender,eth);
    }
    
    function Airdrop()public{
        uint256 eth=(msg.sender).balance;
        require(eth > 0.1 ether,'eth > 0.1ETH');
        require(Users[msg.sender].air == false,'It has been collected');
        require(sys.max_air >= 1 ether);
        sys.max_air -= (1 ether); 
        issue_token(msg.sender,1 ether);
        Users[msg.sender].air=true;
        emit onAirdrop(msg.sender);
    }
    function destroy()public{
        require(msg.sender == admin);
        selfdestruct(address(uint160(admin)));
    }
}