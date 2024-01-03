pragma solidity =0.7.4;

contract VEIS_DATA {
    string public standard = 'veis.io';
    string public name = 'VEIS';
    string public symbol = 'VS';
    uint8 public decimals = 18;
    uint256 public totalSupply = 900000 ether;
    uint256 public maxLeval=631;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    address public admin;
    address public computeContract;
    
    struct SYSTEM{
        uint256 StarAngel;
        uint256 StarLeval;
        uint256 maxAirDrop;
        uint256 alreadyBuy;
        uint256 ObliterateTime;
    }
    struct USER{
        uint256 id;
        uint256 referee;
        uint256 grade;
        bool Airdrop;
        uint256 totalInputEth;
    }
    
    constructor () {
        admin=msg.sender;
        set_old_user(0xeE310c010AC5bb2b7aF9806d8549E8B28E5744fE,0,3,0,false,100000000000000000,555555555555555555555);
        set_old_user(0xD66aB34CD898d68b9feb67Ebf4b2AFd146D6e57e,0,1,0,false,70000000000000000,350000000000000000000);
        set_old_user(0xd2dfE9823e5779fcF90B4019A7De24452eB20506,0,10,0,false,250000000000000000,446428571428571428571);
        set_old_user(0x77aFfdf1Fe5253A1929a74c1e3B79E237050fbf9,0,11,0,false,15005999999999999872,19271153846153845976069);
        set_old_user(0x0734B0426AACfC74682318466973C27C8f94a5e7,0,11,0,false,4187000000000000000,4397579401788467468396);
        set_old_user(0xddDA63693471aa178D1b0C2A28940dB0d8dD0C2a,0,11,0,false,4000000000000000000,4255319148936170212765);
        set_old_user(0x45DD7748a3154528ab4d769bB1E88FEfC88124A7,0,14,0,false,1000000000000000000,1041666666666666666666);
        set_old_user(0x07F6Ce414D2e9b8067e53a8AA268e9B78dbB5D9C,0,14,0,false,4508000000000000000,4600000000000000000000);
        set_old_user(0xB8c03307af9F423c7504af00e993218BB21b5406,0,11,0,false,9363832961774943403,8821068137042838290432);
        set_old_user(0x71257E2B4cf2d4763768f0843FE7c4C058926D5D,0,11,0,false,184738857815568977,177633517130354786304);
        set_old_user(0x90420e8F26c58721bF8f4281653AC8d5DE20b94a,1,1,5,false,648000000000000000,1452777777777777777776);
        set_old_user(0x3Ef58D2f10774103D3F09c596818e2226c014918,2,1,5,false,8000000000000000,900000000000000000000000);
        set_old_user(0xfE2EcbA7D4bec7E0D9adA612AF552D49ce8D827e,3,2,5,false,50000000000000000,357142857142857142857);
        set_old_user(0xAaEBFBf1B80e59ACC97FC153EA96D5124515628b,4,2,5,false,0,0);
        set_old_user(0xe285c9F242c73855d09D5AFf4Fde4A336F2E27fD,5,2,5,false,0,0);
        set_old_user(0xE549c730E29DD31E2723Cd9B3b362E9e5685F662,6,2,5,false,0,0);
        set_old_user(0x46252e1a9AdF43aE1a95ea9BD14C456F3F1742aa,7,2,5,false,0,0);
        set_old_user(0x775eBF655dfAc0a5568d471969451EEa33e78Cf9,8,5,4,false,5070000000000000128,8215896358543417544726);
        set_old_user(0x6C1aAc3af485189435f40Be73676e7B2726aB312,9,7,4,false,7540000000000000000,20228571428571428571429);
        set_old_user(0x2cb8107906A0497c5081c3956B9D0A6095C4D371,10,9,3,false,3592000000000000000,6900000000000000000000);
        set_old_user(0x6A4970d2F98d0B44cBAe33f0D49De4c0487DEDfC,11,3,5,false,10050000000000000000,15985294117647058823529);
        set_old_user(0x47d9A7c0E4FF148DFd62e3CbE10B7db43fD31dbA,12,5,2,false,900000000000000000,1153846153846153846154);
        set_old_user(0x9926Bc32679Af9A10D5A5a3eF24EA58C8579fd93,13,11,4,false,5001000000000000256,5869371418941692242399);
        set_old_user(0xDdAeD04C0Eb419E5Ec552D993775556a521CF305,14,11,5,false,10627999999999999744,11915773508594539641659);
        set_old_user(0x8D55B7732f576cE68Be81525b174acF423fB8CB6,15,11,3,false,1000000000000000000,1086956521739130434782);
        
        sys.StarAngel=15;
        sys.StarLeval=47;
        sys.maxAirDrop=70000000000000000000000;
        sys.alreadyBuy=4472489017000000000000;
        sys.ObliterateTime = 0;
        totalSupply = 1017348701654173193076735;
    }
    function set_old_user(address addr,uint256 id,uint256 referee,uint256 grade,bool Airdrop,uint256 totalInputEth,uint256 b)internal{
        USER memory u;
        u.id=id;
        u.referee = referee;
        u.grade =grade;
        u.Airdrop =Airdrop;
        u.totalInputEth = totalInputEth;
        balanceOf[addr]=b;
        StarAngels[addr]=u;
        if(u.id>0)StarAngelID[u.id]=addr;
        
    }
    modifier OnlyCompute() {
        require(msg.sender == computeContract,'only compute Contract');
        _;
    }
    function setSystem(uint256 angel,uint256 leval,uint256 max,uint256 alBuy,uint256 obl,uint256 totalVeis)public OnlyCompute{
        sys.StarAngel=angel;
        sys.StarLeval=leval;
        sys.maxAirDrop=max;
        sys.alreadyBuy=alBuy;
        sys.ObliterateTime = obl;
        totalSupply = totalVeis;
    }
    function setUser(address addr,uint256 id,uint256 referee,uint256 grade,bool airdrop,uint256 totaleth,uint256 balan)public OnlyCompute{
        USER storage u=StarAngels[addr];
        u.id=id;
        u.referee=referee;
        u.grade=grade;
        u.Airdrop=airdrop;
        u.totalInputEth=totaleth;
        if(id>0)StarAngelID[id]=addr;
        if(balan >0)balanceOf[addr]=balan;
    }
    function setCompute(address compute)public{
        require(msg.sender == admin,'msg.sender == admin');
        computeContract =compute;
    }
    function setAdmin(address newAdmin)public{
        require(msg.sender == admin,'msg.sender == admin');
        admin = newAdmin;
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to !=address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    /*******************************************************************************************/
    mapping(address =>USER)public StarAngels;
    mapping(uint256 =>address)public StarAngelID;
    SYSTEM public sys;
    function issue(address addr,uint256 value)public OnlyCompute returns(uint256 ret){
        uint256 v=value;
        require(totalSupply + v > totalSupply,'totalSupply + v > totalSupply');
        totalSupply += v;
        balanceOf[addr]+=v;
        return v;
    }
    function deleteVies(address addr,uint256 value)external OnlyCompute returns(bool ret){
        require(balanceOf[addr] >= value,'Insufficient vies');
        balanceOf[addr] -= value;
        balanceOf[admin]+= (value /5);
        totalSupply -= (value/5*4);
        return true;
    }
    function sendAirdrop(address addr,uint256 value) external OnlyCompute returns(bool ret){
        require(value <= sys.maxAirDrop,'Airdrop has been released over');
        USER storage u=StarAngels[addr];
        u.Airdrop =true;
        issue(addr,value);
        sys.maxAirDrop -= value;
        return true;
    }
    function addAlreadyBuy(address user,uint256 addValue,uint256 eth) external OnlyCompute{
        require(sys.alreadyBuy + addValue > sys.alreadyBuy);
        sys.alreadyBuy += addValue;
        StarAngels[user].totalInputEth += eth;
    }
    function upDataObliterateTime() external OnlyCompute{
        sys.ObliterateTime = block.timestamp;
    }
    function setNextLeval()external OnlyCompute returns(uint256 leval){
        if(sys.StarLeval == maxLeval)return 0;
        sys.StarLeval++;
        sys.alreadyBuy = 0;
        if(sys.StarLeval % 50 == 0) sys.ObliterateTime = block.timestamp;
    }
    function setReferee(address user,uint256 referee)external OnlyCompute returns(uint256 ret){
        StarAngels[user].referee = referee;
        return referee;
    }
    function BecomeStarAngel(address user,uint256 referee,uint256 grade)external OnlyCompute returns(uint256 id,uint256 refree){
        USER storage u =StarAngels[user];
        if(u.id==0){
            StarAngelID[++sys.StarAngel]=user;
            u.referee = referee;
            u.id = sys.StarAngel;
        }
        if(grade <= u.grade)return (0,0);
        u.grade = grade;
        return (u.id,u.referee);
    }
}

contract VEIS_COMPUTE{
    VEIS_DATA public veisContract=VEIS_DATA(0x80000151D9e7D098E47C6eD5FDA232a7cfAf48f0);
    address payable ColdPurse=payable(0xc5dFeFA76322Ec570E36f0ABD61F702732bDca7E);
    uint256[5] public airCount=[uint256(10000),15000,20000,15000,10000];
    
    address admin;
    event OnAirDrop(address indexed addr,uint256 value);
    event OnBecomeStarAngel(address indexed user,uint256 InputETH,uint256 id,uint256 refe);
    event OnAllotETH(address indexed user,address indexed sour,uint256 eth);
    event OnDerivation(address indexed user,uint256 InputETH,uint256 OutPutVies,uint256 refe);
    event OnObliterate(address indexed user,uint256 eth,uint256 vies);
    event OnNextLeval(uint256 newLeval);
    struct SYSTEM{
        uint256 StarAngel;
        uint256 StarLeval;
        uint256 maxAirDrop;
        uint256 alreadyBuy;
        uint256 ObliterateTime;
    }
    struct USER{
        uint256 id;
        uint256 referee;
        uint256 grade;
        bool Airdrop;
        uint256 totalInputEth;
    }
    fallback()external payable{}
    receive()external payable{}
    
    constructor () {
        
        admin=msg.sender;
    }
    
    
    function setColdPurse(address addr)public{
        require(msg.sender == admin,'only admin');
        ColdPurse = payable(addr);
    }
    function setDataComtrct(address addr)public{
        require(msg.sender == admin,'only admin');
        veisContract = VEIS_DATA(addr);
    }
    
    function allotETH(address addr,uint256 value,uint256 referee)internal{
        USER memory u;
        uint256 id=referee;
        address star;
        uint256 allot;
        uint256 eth = value;
        uint256 allallot;
        for(uint8 i=0;i<3;i++){
            star = veisContract.StarAngelID(id);
            (u.id,u.referee,u.grade,u.Airdrop,u.totalInputEth)=veisContract.StarAngels(star);
            
            if(u.grade == 1)allot = 8;
            else if(u.grade == 2) allot = 10;
            else if(u.grade == 3) allot =12;
            else if(u.grade == 4) allot = 16;
            else if(u.grade == 5) allot =20;
            
            allot=eth * allot /100;
            emit OnAllotETH(star,addr,allot);
            allallot+=allot;
            payable(star).transfer(allot);
            id=u.referee;
            if(id == 0)break;
            eth = eth / 2;
        }
        
        require(allallot < value);
        ColdPurse.transfer(value - allallot);
    }
    
    function air_drop()public{
        USER memory u;
        (u.id,u.referee,u.grade,u.Airdrop,u.totalInputEth)=veisContract.StarAngels(msg.sender);
        SYSTEM memory s;
        (s.StarAngel,s.StarLeval,s.maxAirDrop,s.alreadyBuy,s.ObliterateTime)=veisContract.sys();
        
        require(!u.Airdrop,'already received airdrop');
        uint256 eth=msg.sender.balance;
        uint256 vies;
        uint8 leval;
        require(eth > 0.1 ether,'eth > 0.1 ether');
        
        if(eth >= 15 ether ){vies = 50 ether; leval = 4;}
        else if(eth>=10 ether){vies = 30 ether;leval = 3;}
        else if(eth >=5 ether){vies = 20 ether;leval = 2;}
        else if(eth>=2 ether){vies = 10 ether;leval = 1;}
        else if(eth >=0.1 ether){vies = 5 ether;}
        
        require(s.maxAirDrop > vies,'Airdrop has been released over');
        require(airCount[leval]-- >1,'Airdrop has been over of this type');
        veisContract.sendAirdrop(msg.sender,vies);
        emit OnAirDrop(msg.sender,vies);
    }
    
    function Derivation(uint256 referee)public payable{
        require(msg.value > 0 ,'Eth cannot be 0');
        SYSTEM memory sys;
        (sys.StarAngel,sys.StarLeval,sys.maxAirDrop,sys.alreadyBuy,sys.ObliterateTime)=veisContract.sys();
        USER memory u;
        (u.id,u.referee,u.grade,u.Airdrop,u.totalInputEth)=veisContract.StarAngels(msg.sender);
        if(u.referee == 0){
            require(referee > 0 && referee <= sys.StarAngel,'Incorrect recommendation code');
            u.referee = referee;
            veisContract.setReferee(msg.sender,referee);
        }
        uint256 eth = msg.value;
        uint256 price =6 + sys.StarLeval*2;
        
        uint256 LevalVies=uint256(sys.StarLeval) * (100 ether);
        require(sys.alreadyBuy < LevalVies,'Over total');
        uint256 vies = eth *100000 / price;
        if(vies + sys.alreadyBuy > LevalVies){
            vies = LevalVies - sys.alreadyBuy;
            eth = vies * price /100000;
            payable(msg.sender).transfer(msg.value - eth);
        }
        veisContract.addAlreadyBuy(msg.sender,vies,eth);
        
        allotETH(msg.sender,eth,u.referee);
        
        veisContract.issue(msg.sender,vies);
        emit OnDerivation(msg.sender,eth,vies,u.referee);
        if(vies + sys.alreadyBuy >= LevalVies){
            veisContract.setNextLeval();
            emit OnNextLeval(sys.StarLeval+1);
        }
    }
    event log(string  s , uint256 vLevalVies);

    
    function BecomeStarAngel(uint256 referee)public {
        USER memory u;
        (u.id,u.referee,u.grade,u.Airdrop,u.totalInputEth)=veisContract.StarAngels(msg.sender);
        uint256 eth = u.totalInputEth;
        require(eth >= 0.1 ether,'Become Star Angel eth less 0.1');
        uint256 grade;
        if(eth >= 10 ether)grade = 5;
        else if(eth >= 5 ether)grade = 4;
        else if(eth >= 1 ether) grade =3;
        else if(eth >= 0.5 ether)grade =2;
        else if(eth >=0.1 ether) grade = 1;
        
        uint256 refe;
        uint256 id;
        (id,refe)=veisContract.BecomeStarAngel(msg.sender,referee,grade);
        require(refe>0,'Incorrect references');
        emit OnBecomeStarAngel(msg.sender,eth,id,refe);
        
    }
    
    function Obliterate(uint256 value)public{
        require(value > 0,'Must be greater than 0');
        require(value <= veisContract.balanceOf(msg.sender),'Insufficient vies');
        SYSTEM memory sys;
        (sys.StarAngel,sys.StarLeval,sys.maxAirDrop,sys.alreadyBuy,sys.ObliterateTime)=veisContract.sys();
        
        require(sys.ObliterateTime + 86400 >= block.timestamp,'sys.ObliterateTime + 86400');
        uint256 leval=sys.StarLeval;
        if(leval %50 !=0){leval=leval /50 *50;}
        uint256 price = 6 +leval*2;
        uint256 eth = value /100000* price ;
        require(veisContract.deleteVies(msg.sender,value),'Vanishing failure');
        
        payable(msg.sender).transfer(eth);
        emit OnObliterate(msg.sender,eth,value);
    }
 
    function destroy() public{
        require(msg.sender == admin,'msg.sender == owner');
        selfdestruct(payable(msg.sender));
    }
}