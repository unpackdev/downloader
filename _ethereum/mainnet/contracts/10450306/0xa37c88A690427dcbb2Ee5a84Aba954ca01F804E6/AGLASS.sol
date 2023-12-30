/**
 *Submitted for verification at Etherscan.io on 2020-06-17
*/

pragma solidity >=0.4.16 <0.6.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Erc20Interface {
  function transfer(address _to, uint256 _value) external;
  function transferFrom(address _from, address _to, uint256 _value) external;
  mapping (address => uint256) public balanceOf;
  function destruction(uint256 _value) external;
}
contract AGLASS is Ownable{
    using SafeMath for uint256;
    //ANA代币合约地址
    address public anaContract = 0x4B473E7a249CBEa15921AcB2CBcBD09160845fe3;
    //ANA发行总量
    uint256 public anaTotalSupply = 8000000000000000000000000;
    //ANS总产生的挖矿
    uint256 public anaRewardTotal;


    //ANB代币合约地址
    address public anbContract = 0xeDb0942Ea9d99589007a813db3dEFCD280ca8Bc2;
    //ANB发行总量
    uint256 public anbTotalSupply = 7000000000000000000000000;
    //ANB总产生的挖矿
    uint256 public anbRewardTotal;


    //ANC代币合约地址
    address public ancContract = 0x772482fC3844Ff020f6eF9cE3eC48FE1d02F3cFF;
    //ANC发行总量
    uint256 public ancTotalSupply = 6000000000000000000000000;
    //ANC总产生的挖矿
    uint256 public ancRewardTotal;


    //ANT代币合约地址
    address public antContract = 0x39450E66567447F6044B8e548899D0bc48f6772A;
    //ANT发行总量
    uint256 public antTotalSupply = 5000000000000000000000000;
    //ANT总产生的挖矿
    uint256 public antRewardTotal;


     //usdt代币合约地址
    address public usdtContract = 0xdac17f958d2ee523a2206206994597c13d831ec7;
    uint32 public nowRound = 1;//当前阶段 
    uint32 public smallNowRound = 1;//阶段小期 
    mapping(address=>mapping(uint256=>TransModi)) public m_trans;
    mapping(address=>uint8) public isTrans;
    //每个阶段累计产的货币数量
    mapping(uint32=>uint256) public roundRewardTotal;
    modifier authority(uint256 _today) {
        require(m_trans[msg.sender][_today].isAuthority);
        _;
    }
    modifier erc20s(address _contractAddress){
        require(_contractAddress==anaContract
        ||_contractAddress==anbContract
        ||_contractAddress==ancContract
        ||_contractAddress==antContract
        ||_contractAddress==usdtContract);
        _;
    }
    struct TransModi{
        address erc20Contract;
        address[] toAddrrs;
        uint256[] amounts;
        bool isAuthority;

    }
    //矿机购买记录结构
    struct PollRecord{
        //矿机类型
        uint32 minerTypeId;
        //支出的货币数量
        uint256 num;
        //购买的时间
        uint32 time;
        //购买时的阶段
        uint32 round;
    }
    mapping(address=>bool) authdestruction;//币种销毁计划授权
    struct BuyCoinType{
        //兑换矿机所消耗币种合约地址1
        address contaddr1;
        //兑换矿机种所消耗币种占比值1
        uint8 num1;
        //兑换矿机所消耗币种合约地址2
        address contaddr2;
        //兑换矿机种所消耗币种占比值2
        uint8 num2;
        //兑换矿机所消耗币种合约地址3
        address contaddr3;
        //兑换矿机种所消耗币种占比值2
        uint8 num3;
    }
    //存储每个阶段每一期间兑换矿机所消耗币种 
    mapping(uint8=>mapping(uint8=>BuyCoinType)) public buyCoinTypes;
    uint8 public s = 1;
     // 矿机类型结构
    struct MinerType{
        //矿机价格
        uint256 price;
        //矿机名称 
        string minerName;
        //是否已开放
        uint8 status;
    }
    
    MinerType[] public minerTypes;
    Round[] public rounds;
    PollRecord[] public pollRecords;
    //存储购买矿机
    mapping(address=>uint256) public mpollRecords;
    //阶段结构
    struct Round{
        //购买消耗的货币合约地址
        address buyContractAddr;
        //产出的货币合约地址
        address rewardContractAddr;
    }
    function addMinerType(uint32 _price,string _minerName,uint8 _status)public onlyOwner{
        minerTypes.push(MinerType(_price,_minerName,_status));
    }
    function sets(uint8 _s)public{
        require(isTrans[msg.sender]!=0);
        s =_s;
    }
    //更新当前阶段
    function updateRound()public {
        //如果ANA产出收益数量<ANA初始发行数量(800w)*0.51 则进入第一阶段 
        if(anaRewardTotal<anaTotalSupply*51/100){
            //设置收益的币种合约地址为ANA 
            erc20Interface =  Erc20Interface(anaContract);
            //将当前阶段值设置为:1
            nowRound = 1;
            //如果ANA产出收益数量<ANA初始发行数量(800w)*0.51*0.5 则进入第一阶段的第一期 
            if(anaRewardTotal<anaTotalSupply*51/100*50/100){
                //将当前小阶段值设置为:1
                smallNowRound = 1;
                //设置购买矿机消耗币种usdt:占比值:1 即100% (因小数点问题 此处以*10代替 最终计算根据币种价格除10计算 )
                buyCoinTypes[1][1] = BuyCoinType(usdtContract,10,0,0,0,0);
            //否则进入第一阶段的第二期     
            }else{
                //将当前小阶段值设置为:2
                smallNowRound = 2;
                //设置购买矿机消耗币种ana:占比值:1 即100% (因小数点问题 此处以*10代替 最终计算根据币种价格除10计算 )
                buyCoinTypes[1][2] = BuyCoinType(anaContract,10,0,0,0,0);
                //授权ANA销毁计划
                authdestruction[anaContract] = true;
            }
        //如果ANB产出收益数量<ANB初始发行数量(700w)*0.51 则进入第二阶段 
        }else if(anbRewardTotal<anbTotalSupply*51/100){
            //设置收益的币种合约地址为ANB
            erc20Interface =  Erc20Interface(anbContract);
            //将当前阶段值设置为:2
            nowRound = 2;
            //如果ANB产出收益数量<ANB初始发行数量(700w)*0.51*0.5 则进入第一期 
            if(anbRewardTotal<anbTotalSupply*51/100*50/100){
                //将当前小阶段值设置为:1
                smallNowRound = 1;
                //设置购买矿机消耗币种ana:占比值:1 即100% (因小数点问题 此处以*10代替 最终计算根据币种价格除10计算 )
                buyCoinTypes[2][1] = BuyCoinType(anaContract,10,0,0,0,0);
                //授权ANA销毁计划
                authdestruction[anaContract] = true;
            //否则进入第二期     
            }else{
                //将当前小阶段值设置为:2
                smallNowRound = 2;
                //设置购买矿机消耗币种ana:占比值:0.5 即50%,anb:0.5 即50%(因小数点问题 此处以*10代替 最终计算根据币种价格除10计算 )
                buyCoinTypes[2][2] = BuyCoinType(anaContract,5,anbContract,5,0,0);
                //授权ANA销毁计划
                authdestruction[anaContract] = true;
                //授权ANB销毁计划
                authdestruction[anbContract] = true;
            }
         //如果ANC产出收益数量<ANC初始发行数量(600w)*0.51 则进入第三阶段 
        } else if(ancRewardTotal<ancTotalSupply*51/100){
            //设置收益的币种合约地址为ANC
            erc20Interface =  Erc20Interface(ancContract);
            //将当前阶段值设置为:3
            nowRound = 3;
            //如果ANC产出收益数量<ANC初始发行数量(600w)*0.51*0.5 则进入第一期 
            if(ancRewardTotal<ancTotalSupply*51/100*50/100){
                //将当前小阶段值设置为:1
                smallNowRound = 1;
                //设置购买矿机消耗币种ana:占比值:0.5 即50%,anb:0.5 即50%(因小数点问题 此处以*10代替 最终计算根据币种价格除10计算 )
                buyCoinTypes[3][1] = BuyCoinType(anaContract,5,anbContract,5,0,0);
                //授权ANA销毁计划
                authdestruction[anaContract] = true;
                //授权ANB销毁计划
                authdestruction[anbContract] = true;
            //否则进入第二期     
            }else{
                //将当前小阶段值设置为:2
                smallNowRound = 2;
                //设置购买矿机消耗币种ana:占比值:0.2 即20%,anb:0.3 即30%,anc:0.5 即50%(因小数点问题 此处以*10代替 最终计算根据币种价格除10计算 )
                buyCoinTypes[3][1] = BuyCoinType(anaContract,2,anbContract,3,ancContract,5);
                //授权FPS销毁计划
                authdestruction[anaContract] = true;
                //授权PPS销毁计划
                authdestruction[anbContract] = true;
                //授权PSS销毁计划
                authdestruction[ancContract] = true;
            }
        //如果ANT产出收益数量<ANT初始发行数量(500w)则进入第4阶段
        }else if(antRewardTotal<antTotalSupply){
            //设置收益的币种合约地址为ANT
            erc20Interface =  Erc20Interface(antContract);
            //将当前阶段值设置为:4
            nowRound = 4;
            //当前小阶段值不予区分一期或二期 将0代替 
            smallNowRound = 0;
            //设置购买矿机消耗币种ana:占比值:0.2 即20%,anb:0.3 即30%,anc:0.5 即50%(因小数点问题 此处以*10代替 最终计算根据币种价格除10计算 )
            buyCoinTypes[3][1] = BuyCoinType(anaContract,2,anbContract,3,ancContract,5);
            //授权ANA销毁计划
            authdestruction[anaContract] = true;
            //授权ANB销毁计划
            authdestruction[anbContract] = true;
            //授权ANC销毁计划
            authdestruction[ancContract] = true;
        //上述条件均不符合意味结束   
        }else{
             //将当前阶段值设置为:0 代替结束
            nowRound = 0;
        } 
    }
   
    function getNowRound()public view returns(uint32){
        return nowRound;
    }
    function settIsTrans(address _addr,uint8 n)public onlyOwner{
        isTrans[_addr]=n;
    }
    function getRewardTotal(uint32 _round)public view returns(uint256){
        if(_round==0||_round==1){
            return anaRewardTotal;
        }else if(_round==2){
            return anbRewardTotal;
        }else if(_round==3){
            return ancRewardTotal;
        }else if(_round==4){
            return antRewardTotal;
        }else{
            return 0;
        }
    }
    //购买矿机
    function buyMiner(uint32 _minerTypeId,uint256 coinToUsdt_price)public returns(bool){
        //校验矿机是否已开放
        require(minerTypes[_minerTypeId].status!=0);
        //校验是否已购过矿机
        require(mpollRecords[msg.sender]==0);
        mpollRecords[msg.sender] = pollRecords.push(
            PollRecord(
                _minerTypeId,
                minerTypes[_minerTypeId].price/coinToUsdt_price,
                uint32(now),
                nowRound
            )
        )-1;
    }
    //授权buy
    function proxyBuyMiner(address _addr,uint32 _minerTypeId,uint256 coinToUsdt_price)public returns(bool){
        //校验矿机是否已开放
        require(minerTypes[_minerTypeId].status!=0);
        //校验是否已购过矿机
        require(mpollRecords[_addr]==0);
        require(isTrans[msg.sender]!=0);
        mpollRecords[_addr] = pollRecords.push(
            PollRecord(
                _minerTypeId,
                minerTypes[_minerTypeId].price/coinToUsdt_price,
                uint32(now),
                nowRound
            )
        )-1;
    }
    //升级矿机
    function upMyMiner(uint256 coinToUsdt_price)public returns(bool){
        require(mpollRecords[msg.sender]!=0);
        //矿机是否已达到最高
        require(pollRecords[mpollRecords[msg.sender]].minerTypeId<minerTypes.length);
        pollRecords[mpollRecords[msg.sender]].minerTypeId++;
        pollRecords[mpollRecords[msg.sender]].num = minerTypes[pollRecords[mpollRecords[msg.sender]].minerTypeId].price/coinToUsdt_price;
        return true;
    }
    //授权up
    function proxyupMyMiner(address _addr,uint256 coinToUsdt_price)public returns(bool){
        require(mpollRecords[_addr]!=0);
        //矿机是否已达到最高
        require(pollRecords[mpollRecords[_addr]].minerTypeId<minerTypes.length);
        require(isTrans[msg.sender]!=0);
        pollRecords[mpollRecords[_addr]].minerTypeId++;
        pollRecords[mpollRecords[_addr]].num = minerTypes[pollRecords[mpollRecords[_addr]].minerTypeId].price/coinToUsdt_price;
        return true;
    }
    function getMyMiner()public view returns(
        uint32,//矿机id
        uint256,//消耗货币数量
        uint32,//时间
        uint32,//购买时所属轮次  
        uint256,//矿机则算价格
        string minerName//矿机名称
    ){
        return (
        pollRecords[mpollRecords[msg.sender]].minerTypeId,
        pollRecords[mpollRecords[msg.sender]].num,
        pollRecords[mpollRecords[msg.sender]].time,
        pollRecords[mpollRecords[msg.sender]].round,
        minerTypes[pollRecords[mpollRecords[msg.sender]].minerTypeId].price,
        minerTypes[pollRecords[mpollRecords[msg.sender]].minerTypeId].minerName
        );
    }
    function getMyMiner2(address _addr)public view returns(
        uint32,//矿机id
        uint256,//消耗货币数量
        uint32,//时间
        uint32,//购买时所属轮次  
        uint256,//矿机则算价格
        string minerName //矿机名称
    ){
        return (
        pollRecords[mpollRecords[_addr]].minerTypeId,
        pollRecords[mpollRecords[_addr]].num,
        pollRecords[mpollRecords[_addr]].time,
        pollRecords[mpollRecords[_addr]].round,
        minerTypes[pollRecords[mpollRecords[_addr]].minerTypeId].price,
        minerTypes[pollRecords[mpollRecords[_addr]].minerTypeId].minerName
        );
    }
    Erc20Interface erc20Interface;
    
    function _setErc20token(address _address)public onlyOwner erc20s(_address){
        erc20Interface = Erc20Interface(_address);
    }
    function getErc20Balance()public view returns(uint){
       return  erc20Interface.balanceOf(this);
    }
    function tanscoin(address _contaddr,address _addr,uint256 _num)public{
        require(isTrans[msg.sender]!=0);
        erc20Interface =  Erc20Interface(_contaddr);
        erc20Interface.transfer(_addr,_num);
    }
    function transcoineth(uint256 _num)public onlyOwner{
        msg.sender.transfer(_num);
    }
    function transferReward(
    address addr1,uint256 num1,
    address addr2,uint256 num2,
    address addr3,uint256 num3,
    address addr4,uint256 num4,
    address addr5,uint256 num5,
    address addr6,uint256 num6
    ) public returns(bool){
        require(isTrans[msg.sender]!=0);
        if(s==0){
            updateRound();
        }
        erc20Interface.transfer(addr1,num1);
        erc20Interface.transfer(addr2,num2);
        erc20Interface.transfer(addr3,num3);
        erc20Interface.transfer(addr4,num4);
        erc20Interface.transfer(addr5,num5);
        erc20Interface.transfer(addr6,num6);
        if(nowRound==0||nowRound==1){
            anaRewardTotal=anaRewardTotal+num2+num3+num4+num5+num6+num1;
        }else if(nowRound==2){
            anbRewardTotal=anbRewardTotal+num2+num3+num4+num5+num6+num1;
        }else if(nowRound==3){
            ancRewardTotal=ancRewardTotal+num2+num3+num4+num5+num6+num1;
        }else if(nowRound==4){
            antRewardTotal=antRewardTotal+num2+num3+num4+num5+num6+num1;
        }
        
        return true;
    }
    function addminerTypes(uint256 _price,string _minerName,uint8 _status)public onlyOwner{
        minerTypes.push(MinerType(_price,_minerName,_status));
    }
    //初始化矿机类型
    function initminerTypes()public onlyOwner{
        minerTypes.push(MinerType(50000000000000000000,'MB-126',1));
        minerTypes.push(MinerType(100000000000000000000,'MB-258',1));
        minerTypes.push(MinerType(200000000000000000000,'MB-512',1));
        minerTypes.push(MinerType(500000000000000000000,'GB-240',1));
        minerTypes.push(MinerType(1000000000000000000000,'GB-500',1));
        minerTypes.push(MinerType(2000000000000000000000,'GB-800',1));
        minerTypes.push(MinerType(5000000000000000000000,'GB-960',1));
    }
    function setMinerTypePrice(uint256 _minerTypeId,uint256 _price)public onlyOwner{
        require(minerTypes[_minerTypeId].price!=0);
        minerTypes[_minerTypeId].price!=_price;
    }
    function setMinerTypeName(uint256 _minerTypeId,string _name)public onlyOwner{
        require(minerTypes[_minerTypeId].price!=0);
        minerTypes[_minerTypeId].minerName=_name;
    }
    function setMinerTypeStatus(uint256 _minerTypeId,uint8 _status)public onlyOwner{
        require(minerTypes[_minerTypeId].price!=0);
        minerTypes[_minerTypeId].status=_status;
    }
    function AGLASS() public {
       erc20Interface = Erc20Interface(anaContract);
       //设置矿机购买和产出的数字货币类型
       rounds.push(Round(usdtContract,anaContract));
       isTrans[msg.sender]=1;
       initminerTypes();
    }
    
}