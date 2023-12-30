/**
 *Submitted for verification at Etherscan.io on 2020-10-17
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
contract ARCHIMEDES is Ownable{
    using SafeMath for uint256;
    //byc代币合约地址
    address public bycContract = 0xba8CDd13Af9774DF75cBA6Fa2a1fF47A48D034b8;
    //byc发行总量
    uint256 public bycTotalSupply = 10000000000000000000000000;
    //byc总产生的挖矿
    uint256 public bycRewardTotal;


    //lec代币合约地址
    address public lecContract = 0x16F9234c72e5938B7Ad11fE0532A7E7666C5BFe3;
    //lec发行总量
    uint256 public lecTotalSupply = 9000000000000000000000000;
    //lec总产生的挖矿
    uint256 public lecRewardTotal;


    //mcc代币合约地址
    address public mccContract = 0x4857Ab2B2D48D79fdeD9F0e868521C8F144E3305;
    //mcc发行总量
    uint256 public mccTotalSupply = 8000000000000000000000000;
    //mcc总产生的挖矿
    uint256 public mccRewardTotal;


    //gtc代币合约地址
    address public gtcContract = 0x455BA35C5d8154350e6BEc71489137f8eA684177;
    //gtc发行总量
    uint256 public gtcTotalSupply = 7000000000000000000000000;
    //gtc总产生的挖矿
    uint256 public gtcRewardTotal;




    //fec代币合约地址
    //address public fecContract = 0xFFBCf46Be3079c7fB226b2256125F513662c0674;
    //fec发行总量
    //uint256 public fecTotalSupply = 5000000000000000000000000;
    //fec总产生的挖矿
    //uint256 public fecRewardTotal;

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
        require(_contractAddress==bycContract
        ||_contractAddress==lecContract
        ||_contractAddress==mccContract
        ||_contractAddress==gtcContract
//      ||_contractAddress==fecContract
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
        //如果byc产出收益数量<byc初始发行数量(1000w)*0.51 则进入第一阶段 
        if(bycRewardTotal<bycTotalSupply*51/100){
            //设置收益的币种合约地址为byc 
            erc20Interface =  Erc20Interface(bycContract);
            //将当前阶段值设置为:1
            nowRound = 1;
            //如果byc产出收益数量<byc初始发行数量(1000w)*0.51*0.5 则进入第一阶段的第一期 
            if(bycRewardTotal<bycTotalSupply*51/100*50/100){
                //将当前小阶段值设置为:1
                smallNowRound = 1;
                //设置购买矿机消耗币种usdt:占比值:1 即100% (因小数点问题 此处以*10代替 最终计算根据币种价格除10计算 )
                buyCoinTypes[1][1] = BuyCoinType(usdtContract,10,0,0,0,0);
            //否则进入第一阶段的第二期     
            }else{
                //将当前小阶段值设置为:2
                smallNowRound = 2;
                //设置购买矿机消耗币种byc:占比值:1 即100% (因小数点问题 此处以*10代替 最终计算根据币种价格除10计算 )
                buyCoinTypes[1][2] = BuyCoinType(bycContract,10,0,0,0,0);
                //授权byc销毁计划
                authdestruction[bycContract] = true;
            }
        //如果lec产出收益数量<lec初始发行数量(900w)*0.51 则进入第二阶段 
        }else if(lecRewardTotal<lecTotalSupply*51/100){
            //设置收益的币种合约地址为lec
            erc20Interface =  Erc20Interface(lecContract);
            //将当前阶段值设置为:2
            nowRound = 2;
            //如果lec产出收益数量<lec初始发行数量(900w)*0.51*0.5 则进入第一期 
            if(lecRewardTotal<lecTotalSupply*51/100*50/100){
                //将当前小阶段值设置为:1
                smallNowRound = 1;
                //设置购买矿机消耗币种byc:占比值:1 即100% (因小数点问题 此处以*10代替 最终计算根据币种价格除10计算 )
                buyCoinTypes[2][1] = BuyCoinType(bycContract,10,0,0,0,0);
                //授权byc销毁计划
                authdestruction[bycContract] = true;
            //否则进入第二期     
            }else{
                //将当前小阶段值设置为:2
                smallNowRound = 2;
                //设置购买矿机消耗币种byc:占比值:0.5 即50%,lec:0.5 即50%(因小数点问题 此处以*10代替 最终计算根据币种价格除10计算 )
                buyCoinTypes[2][2] = BuyCoinType(bycContract,5,lecContract,5,0,0);
                //授权byc销毁计划
                authdestruction[bycContract] = true;
                //授权lec销毁计划
                authdestruction[lecContract] = true;
            }
         //如果mcc产出收益数量<mcc初始发行数量(800w)*0.51 则进入第三阶段 
        } else if(mccRewardTotal<mccTotalSupply*51/100){
            //设置收益的币种合约地址为mcc
            erc20Interface =  Erc20Interface(mccContract);
            //将当前阶段值设置为:3
            nowRound = 3;
            //如果mcc产出收益数量<mcc初始发行数量(800w)*0.51*0.5 则进入第一期 
            if(mccRewardTotal<mccTotalSupply*51/100*50/100){
                //将当前小阶段值设置为:1
                smallNowRound = 1;
                //设置购买矿机消耗币种byc:占比值:0.5 即50%,lec:0.5 即50%(因小数点问题 此处以*10代替 最终计算根据币种价格除10计算 )
                buyCoinTypes[3][1] = BuyCoinType(bycContract,5,lecContract,5,0,0);
                //授权byc销毁计划
                authdestruction[bycContract] = true;
                //授权lec销毁计划
                authdestruction[lecContract] = true;
//          授权gtc销毁计划
//           authdestruction[mccContract] = true;				
            //否则进入第二期     
            }else{
                //将当前小阶段值设置为:2
                smallNowRound = 2;
                //设置购买矿机消耗币种byc:占比值:0.2 即20%,lec:0.3 即30%,mcc:0.5 即50%(因小数点问题 此处以*10代替 最终计算根据币种价格除10计算 )
                buyCoinTypes[3][1] = BuyCoinType(bycContract,2,lecContract,3,mccContract,5);
                //授权byc销毁计划
                authdestruction[bycContract] = true;
                //授权lec销毁计划
                authdestruction[lecContract] = true;
                //授权mcc销毁计划
                authdestruction[mccContract] = true;
            }
        //如果gtc产出收益数量<gtc初始发行数量(700w)则进入第4阶段
        }else if(gtcRewardTotal<gtcTotalSupply){
            //设置收益的币种合约地址为gtc
            erc20Interface =  Erc20Interface(gtcContract);
            //将当前阶段值设置为:4
            nowRound = 4;
            //当前小阶段值不予区分一期或二期 将0代替 
            smallNowRound = 0;
            //设置购买矿机消耗币种byc:占比值:0.2 即20%,lec:0.3 即30%,mcc:0.5 即50%(因小数点问题 此处以*10代替 最终计算根据币种价格除10计算 )
            buyCoinTypes[3][1] = BuyCoinType(bycContract,2,lecContract,3,mccContract,5);
            //授权byc销毁计划
            authdestruction[bycContract] = true;
            //授权lec销毁计划
            authdestruction[lecContract] = true;
            //授权mcc销毁计划
            authdestruction[mccContract] = true;
//			授权gtc销毁计划
//			authdestruction[mccContract] = true;
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
            return bycRewardTotal;
        }else if(_round==2){
            return lecRewardTotal;
        }else if(_round==3){
            return mccRewardTotal;
        }else if(_round==4){
            return gtcRewardTotal;
        }//else if(_round==5){
         // return fecRewardTotal;
//        }
        else{
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
            bycRewardTotal=bycRewardTotal+num2+num3+num4+num5+num6+num1;
        }else if(nowRound==2){
            lecRewardTotal=lecRewardTotal+num2+num3+num4+num5+num6+num1;
        }else if(nowRound==3){
            mccRewardTotal=mccRewardTotal+num2+num3+num4+num5+num6+num1;
        }else if(nowRound==4){
            gtcRewardTotal=gtcRewardTotal+num2+num3+num4+num5+num6+num1;
        }//else if(nowRound==5){
//          fecRewardTotal=fecRewardTotal+num2+num3+num4+num5+num6+num1;
//        }
        
        return true;
    }
    function addminerTypes(uint256 _price,string _minerName,uint8 _status)public onlyOwner{
        minerTypes.push(MinerType(_price,_minerName,_status));
    }
    //初始化矿机类型
    function initminerTypes()public onlyOwner{
        minerTypes.push(MinerType(50000000000000000000,'A-100',1));
        minerTypes.push(MinerType(100000000000000000000,'B-500',1));
        minerTypes.push(MinerType(200000000000000000000,'C-1000',1));
        minerTypes.push(MinerType(500000000000000000000,'D-1500',1));
        minerTypes.push(MinerType(1000000000000000000000,'E-3000',1));
        minerTypes.push(MinerType(2000000000000000000000,'F-5000',1));
        minerTypes.push(MinerType(5000000000000000000000,'G-20',1));
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
    function ARCHIMEDES() public {
       erc20Interface = Erc20Interface(bycContract);
       //设置矿机购买和产出的数字货币类型
       rounds.push(Round(usdtContract,bycContract));
       isTrans[msg.sender]=1;
       initminerTypes();
    }
    
}