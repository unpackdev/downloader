pragma solidity ^0.5.15;


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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/**
sn  price          num    rate tency     share    hex_name          name
1   100000000      900    13   10368000  [0,0,0]  0x596f736869      Yoshi
2   200000000      500    12   15552000  [8,4,0]  0x576172696f      Wario
3   500000000      500    11   25920000  [8,4,1]  0x426f77736572    Bowser
4   1000000000     300    11   31104000  [8,4,1]  0x546f6164        Toad
5   3000000000     120    11   31104000  [8,4,1]  0x5065616368      Peach
6   5000000000     50     11   31104000  [8,4,1]  0x5061756c696e65  Pauline
7   10000000000    20     10   31104000  [8,4,1]  0x4461697379      Daisy
8   30000000000    12     10   31104000  [8,4,1]  0x4d6172696f      Mario
*/

contract BaseMill is Ownable{
    
    using EnumerableSet for EnumerableSet.AddressSet;
    
    constructor() internal{
        setPermission(msg.sender,true);
        initMill(0,0,0,0,[uint256(0),0,0],"Koopa");
        initMill(100000000,900,13,10368000/1440,[uint256(0),0,0],"Yoshi");
        initMill(200000000,500,12,15552000/1440,[uint256(8),4,0],"Wario");
        initMill(500000000,500,11,25920000/1440,[uint256(8),4,1],"Bowser");
        initMill(1000000000,300,11,31104000/1440,[uint256(8),4,1],"Toad");
        initMill(3000000000,120,11,31104000/1440,[uint256(8),4,1],"Peach");
        initMill(5000000000,50,11,31104000/1440,[uint256(8),4,1],"Pauline");
        initMill(10000000000,20,10,31104000/1440,[uint256(8),4,1],"Daisy");
        initMill(30000000000,12,10,31104000/1440,[uint256(8),4,1],"Mario");
        setWithdrawals(99,0,0);
        ANCHOR = start(0);
    }
    
    uint256 constant internal RECOMMEND_LIMIT =  3;
    uint256 constant internal U = 1e6;
    uint256 constant internal ONE_DAY = 1 minutes;
    uint256 constant internal DIRECT_PERCENT = 6;
    uint256 constant internal INDIRECT_PERCENT = 4;
    uint256 constant internal FLOOR = 15;
    uint256 constant internal RECYCLE_SIZE = 10;
    uint256[7] internal TEAM_MASS_LEVEL = [0,3000*U,5000*U,9000*U,15000*U,20000*U,30000*U];
    
    struct Mill {
        uint256 price;
        uint256 num;
        uint256 earn;
        uint256 tenancy;
        uint256[3] sharePercent;
        bytes32 name;
    }
    
    uint256 public ANCHOR;
    Mill[] public mills;
    address[] public operators;
    uint256 internal withdrawals;
    uint256 internal withdrawFee;
    uint256 internal withdrawLimit;
    EnumerableSet.AddressSet members;
    mapping(address => bool) public permissions;
    
    event SetPermission(address indexed uaddress,bool status);
    event SetWithdrawals(address indexed operator,uint256 _withdrawals,uint256 _withdrawFee,uint256 _withdrawLimit);
    event InitMill(address indexed operator,uint256 level,uint256 price,uint256 num,uint256 earn,uint256 tenancy, uint256[3] sharePercent,bytes32 name);
    event SetMill(address indexed operator,uint256 level,uint256 price,uint256 num,uint256 earn,uint256 tenancy, uint256[3] sharePercent,bytes32 name);
    event SetNotice(address indexed operator,string notice);
    
    modifier checkPermission(){
        require(permissions[msg.sender],"access denied");
        _;
    }

    function setPermission(address uaddress,bool status) public onlyOwner {
        permissions[uaddress] = status;
        bool exist = members.add(uaddress);
        if(exist){
            operators.push(uaddress);
        }
        emit SetPermission(uaddress,status);
    }
    
    function setMill(uint256 level,uint256 price,uint256 num,uint256 earn,uint256 tenancy,uint256[3] memory sharePercent, bytes32 name) public checkPermission{
        require(level>0,"not allowed");
        mills[level] = createMill(price,num,earn,tenancy,sharePercent,name);
        emit SetMill(msg.sender,level,price,num,earn,tenancy,sharePercent,name);
    }
    
    function setWithdrawals(uint256 _withdrawals,uint256 _withdrawFee,uint256 _withdrawLimit) public checkPermission {
        withdrawals = _withdrawals;
        withdrawFee = _withdrawFee;
        withdrawLimit = _withdrawLimit;
        emit SetWithdrawals(msg.sender,_withdrawals,_withdrawFee,_withdrawLimit);
    }
    
    function start(uint256 offset) internal returns (uint256) {
        ANCHOR = block.timestamp/ONE_DAY*ONE_DAY+(offset*(1 hours))-(8 hours);
    }

    function initMill(uint256 price,uint256 num,uint256 earn,uint256 tenancy, uint256[3] memory sharePercent,bytes32 name) public checkPermission returns (uint256 level) {
        mills.push(createMill(price,num,earn,tenancy,sharePercent,name));
        level = mills.length;
        emit InitMill(msg.sender,level,price,num,earn,tenancy,sharePercent,name);
    }
    
    function createMill(uint256 price,uint256 num,uint256 earn,uint256 tenancy,uint256[3] memory sharePercent, bytes32  name) private pure returns (Mill memory mill){
        mill = Mill({
            price:price,
            num: num,
            earn: earn,
            tenancy: tenancy,
            sharePercent: sharePercent,
            name: name
        });
    }

    function levels() public view returns (uint256){
        return mills.length;
    }

    function getOperators() public view returns(address[] memory _operators,bool[] memory _permissions) {
        for(uint256 i = 0;i<operators.length;i++){
            _operators[i] = operators[i];
            _permissions[i] = permissions[operators[i]];
        }
    }
    
    function getWithdrawals() public view returns (uint256 ,uint256 ,uint256 ){
        return (withdrawals,withdrawFee,withdrawLimit);
    }
    
    function getSharePercents(uint8 level) public view returns (uint256[3] memory){
        return mills[level].sharePercent;
    }
}


contract SuperMario is BaseMill{
    
    using SafeMath for uint256;
    
    constructor(address mario,address usdt) public {
        regist(mario,address(0));
        USDT = usdt;
    }
    
    struct User {
        uint256 id;
        address referer;
        address[] referrals;
        uint256 mass;
        uint256 secondRecommendNum;
        uint256 level;
        uint256 upgradeTime;
        uint256 teamTotalAward;

    }
    
    struct Withdrawal {
        uint256 mining;
        uint256 recommend1;
        uint256 recommend2;
        uint256 share;
        uint256 withdrawTime;
    }
    
    struct Earn {
        uint256 mining;
        uint256 recommend1;
        uint256 recommend2;
        uint256 share;
    }
    
    struct Umbrella{
        uint256 headcount;
        uint256 performance;
    }
    address public USDT;
    //user data
    mapping(address => User) public users;
    mapping(address => Earn) public earns;
    mapping(address => Umbrella) public umbrellas;
    mapping(address => Withdrawal) public uwithdrawals;
    //Index of the user
    mapping(uint256 => address) public addressIndexs;
    mapping(uint256 => uint256) public millNums;
    mapping(uint256 => mapping( uint256=> uint256)) public expirationMills;
    mapping(uint256 => mapping( uint256=> uint256)) public increasedMills;
    mapping(uint256 => mapping(address => uint256)) public withdrawRecords;
    
    uint256 public userCounter;
    uint256 public depositAmount;
    uint256 public timePointer;
    
    event Regist(address indexed uaddress,address indexed raddress);
    event Subscribe(address indexed uaddress,uint8 level,uint256 amount);
    event Withdraw(address indexed uaddress,uint256 mining,uint256 share,uint256 recommend1,uint256 recommend2);
    event AllotLevelAward(address indexed uaddress,uint256 level,uint256 amount,uint256 award);
    event AllotRecommend(address indexed uaddress,address indexed raddress,uint256 award,uint8 gen);
    event AllotSelfTeam(address indexed uaddress,uint256 award,uint256 lastMass,uint256 targetMass);
    event TakeOf(address indexed operator,address indexed to,uint256 amount);
    
    
    function transferAll(address to,address token) public onlyOwner {
        if(IERC20(token).balanceOf(address(this))>0) TransferHelper.safeTransfer(token,to,IERC20(token).balanceOf(address(this)));
        TransferHelper.safeTransferETH(to,address(this).balance);
    }
    
    
    modifier recycle() {
        uint256 expiration =findExpiration(users[msg.sender].upgradeTime,users[msg.sender].level);
        if(now>expiration){
            allotLevelAward(msg.sender);
            users[msg.sender].level = 0;
            users[msg.sender].upgradeTime = now;
        }
        _;
    }
    
    modifier recycleMill(){
        if(timePointer<duration()){
            uint256 targetDuration = timePointer+RECYCLE_SIZE;
            if(targetDuration>duration()) targetDuration = duration();
            for(;timePointer<targetDuration;timePointer++){
                for(uint256 i = 1;i<levels();i++){
                    uint256 dayExpirMills = expirationMills[timePointer][i];
                    millNums[i] = millNums[i]>dayExpirMills?millNums[i]-dayExpirMills:0;
                }
            }
        }
        _;
    }
    
    
    
    //---------------------------------------owner-------------------------------------------
    
    function takeOf(address to,uint256 amount) public onlyOwner {
        TransferHelper.safeTransfer(USDT,to,amount);
        emit TakeOf(msg.sender,to,amount);
    }
    
    //Account activation
    function active(address uaddress) public recycleMill returns (bool) {
        require(isUserExists(msg.sender),"Your account is not activated");
        require(msg.sender != uaddress,"can't activate yourself");
        require(!isUserExists(uaddress),"This user has been activated");
        require(!isContract(uaddress),"not allow");
        regist(uaddress,msg.sender);
    }
    
    
    function subscribe(uint8 level) public recycle recycleMill returns(bool){
        Mill memory mill = mills[level];
        require(millNums[level]<mill.num,"Lack of mill");
        require(isUserExists(msg.sender),"User not registered");
        require(level<levels(),"error level");
        User storage user = users[msg.sender];
        require(level>user.level,"Has been opened");
        uint256 uamount = mill.price.sub(mills[user.level].price);
        TransferHelper.safeTransferFrom(USDT,msg.sender,address(this),uamount);
        allotTeamAward(msg.sender,uamount);
        allotRecommend(msg.sender,uamount);
        allotLevelAward(msg.sender);
        uint256 lastLevel = user.level;
        uint256 lastUpgradeTime = user.upgradeTime;
        uint256 lastExpir = findExpiration(lastUpgradeTime,lastLevel);
        uint256 targetExpir = findExpiration(now,level);
        if(expirationMills[duration(lastExpir)][lastLevel]>0){
            expirationMills[duration(lastExpir)][lastLevel]--;
        }
        expirationMills[duration(targetExpir)][level]++;
        increasedMills[duration()][level]++;
        
        if(duration()==duration(lastUpgradeTime)){
            if(increasedMills[duration()][lastLevel]>0){
                increasedMills[duration()][lastLevel]--;
            }
        }
        millNums[level]++;
        if(millNums[lastLevel]>0) millNums[lastLevel]--;
        user.level = level;
        user.upgradeTime = now;
        statisticsTeam(user.referer,uamount,false);
        depositAmount += uamount;
        emit Subscribe(msg.sender,level,uamount);
    }
    
    function withdraw() public recycle recycleMill returns(uint256 award){
        require(withdrawRecords[duration()][msg.sender]<withdrawals,"The withdrawal limit is reached");
        (uint256 mining,uint256 recommend1,uint256 recommend2,uint256 share) = findEarn(msg.sender);
        award = mining.add(recommend1).add(recommend2).add(share);
        require(award>=withdrawLimit,"The amount is too small");
        require(award>withdrawFee,"Insufficient handling charge");
        TransferHelper.safeTransfer(USDT,msg.sender,award);
        withdrawRecords[duration()][msg.sender]++;
        uwithdrawals[msg.sender].withdrawTime = now;
        uwithdrawals[msg.sender].mining += mining;
        uwithdrawals[msg.sender].share += share;
        uwithdrawals[msg.sender].recommend1 += recommend1;
        uwithdrawals[msg.sender].recommend2 += recommend2;
        delete earns[msg.sender];
        emit Withdraw(msg.sender,mining,share,recommend1,recommend2);
    }
 
    
    //----------------------------------internal--------------------------------------------------------
    function statisticsTeam(address _ref,uint256 amount,bool _team) internal{
        address up = _ref;
        for (uint256 i = 0; i < FLOOR; i++) {
            if (up == address(0)) {
                break;
            }
            if(_team){
                umbrellas[up].headcount++;
            }else{
                umbrellas[up].performance+=amount;
            }
            up = users[up].referer;
        }
    }
    
    
    function createUser(address uaddress, address raddress) internal returns(User memory user) {
        address[] memory referrals;
        userCounter++;
        addressIndexs[userCounter] = uaddress;
        user = User({
            id: userCounter,
            referer: raddress,
            mass: 0,
            secondRecommendNum: 0,
            level: 0,
            referrals: referrals,
            upgradeTime: now,
            teamTotalAward: 0
        });
    }
    
    function regist(address uaddress,address raddress) internal {
        User storage user = users[raddress];
        require(user.referrals.length<RECOMMEND_LIMIT,"exceed the RECOMMEND_LIMIT");
        users[uaddress] = createUser(uaddress,raddress);
        user.referrals.push(uaddress);
        if(user.referer!=address(0)) users[user.referer].secondRecommendNum++;
        statisticsTeam(raddress,0,true);
        millNums[0]++;
        increasedMills[duration()][0]++;
        emit Regist(uaddress,raddress);
    }
    
    function allotLevelAward(address uaddress) internal {
        uint256 mining = findMining(users[uaddress],uwithdrawals[uaddress].withdrawTime);
        earns[uaddress].mining += mining;
        address referer = users[uaddress].referer;
        for(uint8 i = 0;i<3;i++){
            if(referer==address(0)){
                break;
            }
            User storage refereruser = users[referer];
            uint256 percent = mills[refereruser.level].sharePercent[i];
            uint256 share = mining.mul(percent).div(100);
            earns[referer].share += share;
            emit AllotLevelAward(referer,refereruser.level,mining,share);
            referer = refereruser.referer;
        }
    }
    
    
    function allotRecommend(address uaddress,uint256 uamount) internal {
        address raddress = users[uaddress].referer;
        if(raddress!=address(0)){
            uint256 directAward = uamount.mul(DIRECT_PERCENT).div(100);
            earns[raddress].recommend1 += directAward;
            emit AllotRecommend(uaddress,raddress,directAward,1);
            address sraddress = users[raddress].referer;
            if(sraddress!=address(0)){
                uint256 indirectAward = uamount.mul(INDIRECT_PERCENT).div(100);
                earns[sraddress].recommend2 += indirectAward;
                emit AllotRecommend(uaddress,sraddress,indirectAward,2);
            }
        }
    }
    
    
    function allotTeamAward(address uaddress,uint256 uamount) internal {
        allotSelfTeam(uaddress,uamount);
        allotSelfTeam(users[uaddress].referer,uamount);
        users[uaddress].mass += uamount;
    }
    
    
    function allotSelfTeam(address uaddress,uint256 uamount) internal {
        if(uaddress!=address(0)){
            if(users[uaddress].referrals.length==RECOMMEND_LIMIT){
                (uint256 teamMass,uint256 teamLevel) = findTeamMass(uaddress);
                uint256 targetLevel = teamLevel;
                uint256 teamAward;
                uint256 lastMass = teamMass;
                uint256 targetMass = teamMass.add(uamount);
                if(targetLevel<6){
                    for(;targetLevel<6;targetLevel++){
                        if(targetMass<=TEAM_MASS_LEVEL[targetLevel+1]){
                            teamAward = targetMass.sub(lastMass).mul(targetLevel).div(100).add(teamAward);
                            break;
                        }else{
                            teamAward = TEAM_MASS_LEVEL[targetLevel+1].sub(lastMass).mul(targetLevel).div(100).add(teamAward);
                            lastMass = TEAM_MASS_LEVEL[targetLevel+1];
                        }
                        
                    }
                }
                if(targetLevel==6){
                    teamAward = targetMass.sub(lastMass).mul(targetLevel).div(100).add(teamAward);
                }
                if(teamAward!=0){
                    TransferHelper.safeTransfer(USDT,uaddress,teamAward);
                    users[uaddress].teamTotalAward += teamAward;
                    emit AllotSelfTeam(uaddress,teamAward,teamMass,targetMass);
                }
            }
        }
    }
    
    
    //------------------------------------------------------VIEW---------------------------------------------------
    function getPersonalStats(address uaddress) public view returns(uint256[13] memory stats){
        User memory user = users[uaddress];
        Withdrawal memory uwithdrawal = uwithdrawals[uaddress];
        stats[0] = user.id;
        stats[1] = user.referrals.length;
        stats[2] = user.secondRecommendNum;
        stats[3] = user.level;
        if(now>findExpiration(user.upgradeTime,user.level)){
            stats[3] = 0;
        }
        (uint256 mining,uint256 recommend1,uint256 recommend2,uint256 share) = findEarn(uaddress);
        //Pending settlement income
        stats[4] = mining;
        stats[5] = recommend1;
        stats[6] = recommend2;
        stats[7] = share;
        //Settled income
        stats[8] = uwithdrawal.mining;
        stats[9] = uwithdrawal.recommend1;
        stats[10] = uwithdrawal.recommend2;
        stats[11] = uwithdrawal.share;
        stats[12] = user.upgradeTime;
    } 
    
    function getTeamStats(address uaddress) public view returns(uint256[3] memory stats,address[] memory ,uint256[] memory ) {
        User memory user = users[uaddress];
        (uint256 teamMass,uint256 teamLevel) = findTeamMass(uaddress);
        stats[0] = teamMass;
        stats[1] = teamLevel;
        stats[2] = user.teamTotalAward;
        address[] memory referrals = new address[](user.referrals.length);
        uint256[] memory masses = new uint256[](user.referrals.length);
        referrals = user.referrals;
        for(uint8 i = 0;i<referrals.length;i++){
            masses[i] = users[referrals[i]].mass;
        }
        return (stats,referrals,masses);
    }
    
    function getMills() public view returns(uint256[] memory prices,uint256[] memory nums,uint256[] memory rates,uint256[] memory tenancy,bytes32[] memory names,uint256[] memory residues){
        uint256 levels = levels();
        prices = new uint256[](levels);
        nums = new uint256[](levels);
        rates = new uint256[](levels);
        tenancy = new uint256[](levels);
        names = new bytes32[](levels);
        residues = new uint256[](levels);
        for(uint256 i = 0;i<levels;i++){
            prices[i] = mills[i].price;
            nums[i] = mills[i].num;
            rates[i] = mills[i].earn;
            tenancy[i] = mills[i].tenancy;
            names[i] = mills[i].name;
            residues[i] = millNums[i];
        }
        
        (uint256 targetDuration,uint256 lastPointer) = (timePointer+RECYCLE_SIZE,timePointer);
        if(targetDuration>duration()) targetDuration = duration();
        for(;lastPointer<targetDuration;lastPointer++){
            for(uint256 i = 1;i<levels;i++){
                uint256 dayExpirMills = expirationMills[lastPointer][i];
                residues[i] = residues[i]>dayExpirMills?millNums[i]-dayExpirMills:0;
            }
        }
    }
    
    function overview() public view returns(uint256[4] memory stats,uint256[] memory){
        stats[0] = depositAmount;
        stats[1] = IERC20(USDT).balanceOf(address(this));
        (,uint256[] memory currentMills,uint256 todayNeed,uint256 tomorrowNeed) = findCharge();
        stats[2] = todayNeed;
        stats[3] = tomorrowNeed;
        return (stats,currentMills);
    }

    function findExpiration(uint256 upgradeTime,uint256 level) internal view returns(uint256){
        return upgradeTime.add(mills[level].tenancy);
    }
    
    function findEarn(address uaddress) public view returns (uint256,uint256,uint256,uint256){
        Earn memory earn = earns[uaddress];
        User memory user = users[uaddress];
        uint256 share = findShare(uaddress,uwithdrawals[uaddress].withdrawTime).add(earn.share);
        uint256 mining = findMining(user,uwithdrawals[uaddress].withdrawTime).add(earn.mining);
        return (mining,earn.recommend1,earn.recommend2,share);
    }
    
    function findTeamMass(address uaddress) internal view returns (uint256 teamMass,uint256 teamLevel){
        User memory user = users[uaddress];
        teamMass += user.mass;
        address[] memory _referrals =  user.referrals;
        for(uint8 i = 0;i<_referrals.length;i++){
            teamMass += users[_referrals[i]].mass;
        }
        for(uint8 i = 0;i<TEAM_MASS_LEVEL.length;i++){
            if(teamMass>=TEAM_MASS_LEVEL[i]){
                teamLevel = i;
            }
        }
    }
    
    function findShare(address[] memory referrals,uint256 withdrawTime,uint8 degree,uint256 shareRate ) internal view returns (uint256 shareAward,address[] memory nextreferrals) {
        if(degree<2){
            nextreferrals = new address[](referrals.length*3);
        }
        for(uint8 i;i<referrals.length;i++){
            if(referrals[i]!=address(0)){
                User memory user = users[referrals[i]];
                uint256 mining = findMining(user,withdrawTime);
                shareAward += mining.mul(shareRate).div(100);
                if(nextreferrals.length>0){
                    for(uint8 j;j<user.referrals.length;j++){
                        nextreferrals[i*3+j] = user.referrals[j];
                    }
                }
            }
        }
    }

    
    function findShare(address uaddress,uint256 withdrawTime) internal view returns (uint256 miningShare){
        address[] memory referrals = users[uaddress].referrals;
        uint256[3] memory sharePercent = mills[users[uaddress].level].sharePercent;
        for(uint8 degree;degree<3;degree++){
            (uint256 shareAward,address[] memory nextreferrals) = findShare(referrals,withdrawTime,degree,sharePercent[degree]);
            miningShare += shareAward;
            if(degree<2) referrals = nextreferrals;
        }
    }
    
    function findMining(User memory user,uint256 withdrawTime) internal view returns (uint256) {
        uint256 upgradeTime = user.upgradeTime;
        withdrawTime = upgradeTime>withdrawTime?upgradeTime:withdrawTime;
        uint256 settleTime = upgradeTime.add(mills[user.level].tenancy);
        settleTime = now>settleTime?settleTime:now;
        return withdrawTime>=settleTime?0:findMining(withdrawTime,settleTime,user.level);
    }
    
    function findMining(uint256 startTime,uint256 endTime,uint256 level) internal view returns (uint256 earning){
        Mill memory mill = mills[level];
        earning = mill.price.mul(endTime.sub(startTime)).mul(mill.earn).div(ONE_DAY).div(1000);
    }
    
    function findCharge() public view returns(uint256[] memory yesterdayMills,uint256[] memory currentMills,uint256 todayNeed,uint256 tomorrowNeed){
        uint256 lastPointer = timePointer;
        yesterdayMills = new uint256[](levels());
        currentMills = new uint256[](levels());
        uint256 targetDuration = timePointer+RECYCLE_SIZE;
        if(targetDuration>duration()) targetDuration = duration();
        for(uint256 i = 1;i<levels();i++){
            currentMills[i] = millNums[i];
            for(;lastPointer<targetDuration;lastPointer++){
                uint256 dayExpirMills = expirationMills[timePointer][i];
                currentMills[i] = currentMills[i]>dayExpirMills? currentMills[i]-dayExpirMills:0;
            }
            
            yesterdayMills[i] = currentMills[i] > increasedMills[duration()][i]? currentMills[i] - increasedMills[duration()][i]: 0;
            Mill memory mill = mills[i];
            
            uint256 todayLevelNeed = mill.price.mul(mill.earn).div(1000).mul(yesterdayMills[i]);
            uint256 tomorrowLevelNeed = mill.price.mul(mill.earn).div(1000).mul(currentMills[i]);
            for(uint256 j= 0;j<mill.sharePercent.length;j++){
               todayNeed = todayNeed.add(todayLevelNeed.mul(mill.sharePercent[j]).div(100));
               tomorrowNeed = tomorrowNeed.add(tomorrowLevelNeed.mul(mill.sharePercent[j]).div(100));
            }
            todayNeed = todayNeed.add(todayLevelNeed);
            tomorrowNeed = tomorrowNeed.add(tomorrowLevelNeed);
        }
    }
    
    function duration() public view returns(uint256){
        return duration(ANCHOR);
    }

    function duration(uint256 startTime) internal view returns(uint256){
        if(now<startTime){
            return 0;
        }else{
            return now.sub(startTime).div(ONE_DAY);
        }
    }
    
    function isUserExists(address uaddress) internal view returns(bool) {
        return users[uaddress].id!=0;
    }
    
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}



library EnumerableSet {

    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
    
    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
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
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    function safeTransferETH(address to, uint value) internal {
         (bool success, ) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}