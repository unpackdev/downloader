pragma solidity >=0.4.22 <0.7.0;

contract U2Binary {
    struct User {
        bool isExist;
        uint256 id;
        uint256 referrerID;
        address referrer;
        address[] referral;
        uint256 poolPosition;
        uint256 poolFee;
        uint256 binaryAmount;
        bool isInPool;
        bool isInBinary;
        string binaryPosition;
      
    }
    struct PaymentList {
        uint256 id;
        address userAddress;
        uint256 poolFee;
        uint256 canEarnMax;
        uint256 incomeAfterTopUp;
        bool status;
        bool isBlocked;
    }
    uint256 public ENTRY_FEE;
    mapping(uint256 => uint256) public POOL_ENTRY;
    mapping(uint256 => uint256) public POOL_COMMISION;
    mapping(address => User) public users;
    mapping(uint256 => address) public userList;
    mapping(uint256 => PaymentList) public paymentList;
    mapping(uint256 => address) public poolList;
    uint256 public currentId;
    uint256 public COMMISSION;
    uint256 public FEE_COMMISSION;
    uint256 public POOL_INCOME;
    uint256 public CARRY_FORWARD;
  
    address public manager; 
    address partner = 0xB1A8DB884f7aB50221c9DA20BCA1FA3A17A7ee3C;
   
    address public PAYMENT_LIST_ONE=0x61ee42B5c0F2240E0979F09F7e3C176aA2795105;

   
    uint256 lockedAmount;
    uint256 public TOP_UP_AFTER_INCOME;
    uint256 public CAN_EARN_INCOME;

    uint256 public currentPoolPosition;
    uint256 public poolStartFrom;

    event Reg(
        address indexed user,
        address indexed referrer,
        uint256 value,
        uint256 level,
        uint256 time
    );
    event UserPoolIncome(
        address indexed user,
        address indexed fromUser,
        uint256 value,
        uint256 myInvestment,
        uint256 time
    );
    
    event BinaryIncome(
        address indexed receiver,
        uint256 amount
    );
    event UserCarryForward(
        address indexed user,
        address indexed fromUser,
        uint256 value,
        uint256 time
    );
    event Topup(
        address indexed user,
        uint256 position,
        uint256 value,
        uint256 time
    );
    event CheckStep(uint256 value, uint256 step);

    constructor(address managerAddress) public {
        manager = managerAddress;
        
        POOL_ENTRY[0] = .1 ether;
        POOL_ENTRY[1] = .25 ether;
        POOL_ENTRY[2] = .5 ether;
        POOL_ENTRY[3] = 1 ether;
        POOL_ENTRY[4] = 2 ether;
        POOL_ENTRY[5] = 5 ether;
        POOL_ENTRY[6] = 10 ether;

        COMMISSION = 25;
        POOL_INCOME = .25 ether;
        CAN_EARN_INCOME = 4;

        User memory user;
        currentId++;
        currentPoolPosition++;
       
        user = User({
            isExist: true,
            id: currentId,
            referrerID: 0,
            referrer: address(0),
            referral: new address[](0),
            poolPosition: currentPoolPosition,
            poolFee: 10 ether,
            binaryAmount: uint256(0),
            isInPool: true,
            isInBinary: false,
            binaryPosition: '0'
           
        });

        users[PAYMENT_LIST_ONE] = user;
        userList[currentId] = PAYMENT_LIST_ONE;
        poolList[currentPoolPosition] = PAYMENT_LIST_ONE;
        poolStartFrom = currentPoolPosition;

        addUserInPoolInternal(PAYMENT_LIST_ONE, 10 ether, 40 ether);

        addUserInPoolInternal(PAYMENT_LIST_ONE, 5 ether, 20 ether);
        addUserInPoolInternal(PAYMENT_LIST_ONE, 2 ether, 8 ether);
        addUserInPoolInternal(PAYMENT_LIST_ONE, 1 ether, 4 ether);
        addUserInPoolInternal(PAYMENT_LIST_ONE, .5 ether, 2 ether);
        addUserInPoolInternal(PAYMENT_LIST_ONE, .25 ether, 1 ether);
        addUserInPoolInternal(PAYMENT_LIST_ONE, .1 ether, .4 ether);

        
    }

    function addUserInPoolAdmin(
        uint256 _position,
        address _userAddress,
        uint256 _investWith,
        uint256 _canEarn,
        uint256 _incomeAfterTopUp
    ) public restricted returns (bool) {
        addUserInPoolInternalWithIncome(
            _position,
            _userAddress,
            _investWith,
            _canEarn,
            _incomeAfterTopUp
        );
        return true;
    }

    function addUserInPoolInternalWithIncome(
        uint256 _position,
        address userAddress,
        uint256 investWith,
        uint256 maxEarn,
        uint256 _incomeAfterTopUp
    ) internal {
        addUserInPool(_position, userAddress, investWith, maxEarn);
        emit Topup(userAddress, _position, investWith, now);
        poolList[_position] = userAddress;
       
    }

    function changePoolStartFromCount(uint256 _count) public restricted {
        poolStartFrom = _count;
    }

    function changeCurrentPoolCount(uint256 _count) public restricted {
        currentPoolPosition = _count;
    }

    function changeCurrentIdCount(uint256 _count) public restricted {
        currentId = _count;
    }

    function addUserInPoolInternal(
        address userAddress,
        uint256 investWith,
        uint256 maxEarn
    ) internal {
        addUserInPool(currentPoolPosition, userAddress, investWith, maxEarn);
        emit Topup(userAddress, currentPoolPosition, investWith, now);
        poolList[currentPoolPosition] = userAddress;
        currentPoolPosition++;
    }

    modifier restricted() {
        require(msg.sender == manager, "Only Manager can update!");
        _;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      
        uint256 c = a / b;
       
        return c;
    }

    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function getUser(address userAddress)
        public
        view
        returns (
            bool,
            uint256 id,
            bool isInPool
            
        )
    {
        return (
            users[userAddress].isExist,
            users[userAddress].id,
            users[userAddress].isInPool
        );
    }

    function getUserReferrals(address userAddress)
        public
        view
        returns (address[] memory)
    {
        return users[userAddress].referral;
    }

    function regUserAdmin(
        uint256 _position,
        address _refId,
        address _userAddress
    ) public restricted returns (bool) {
        require(!users[_userAddress].isExist, "User Already Exits");
        require(users[_refId].isExist, "Upline not exists!");
       

        addInitUserWithPosition(_position, _userAddress, _refId, 0);
       
        return true;
    }

    function regUser(address _refId) public payable returns (bool) {
        require(!users[msg.sender].isExist, "User Already Exits");
        require(users[_refId].isExist, "Upline not exists!");
        addUser(_refId, 0);
        
        joinPool();
        return true;
    }

    

    function joinPool() public payable returns (bool) {
        require(users[msg.sender].isExist, "Register before joing pool!");
        uint256 poolLevel;

        if (msg.value == POOL_ENTRY[0]) {
            poolLevel = 0;
        } else if (msg.value == POOL_ENTRY[1]) {
            poolLevel = 1;
        } else if (msg.value == POOL_ENTRY[2]) {
            poolLevel = 2;
        } else if (msg.value == POOL_ENTRY[3]) {
            poolLevel = 3;
        } else if (msg.value == POOL_ENTRY[4]) {
            poolLevel = 4;
        } else if (msg.value == POOL_ENTRY[5]) {
            poolLevel = 5;
        } else if (msg.value == POOL_ENTRY[6]) {
            poolLevel = 6;
        } else {
            revert("Invalid Pool Entry Fee");
        }
        User storage _user = users[msg.sender];
        
        payPoolIncome(msg.sender, msg.value / 2);
       
        _user.poolPosition = currentPoolPosition;
        _user.isInPool = true;
        _user.poolFee = msg.value;
        _user.binaryAmount += (msg.value / 2);
        lockedAmount += (msg.value / 2);
        
        addUserInPool(
            currentPoolPosition,
            msg.sender,
            msg.value,
            4 * msg.value
        );
        emit Topup(userList[_user.id], currentPoolPosition, _user.poolFee, now);
    }
    
    function investBinary(string memory position) public returns(bool) {
        User storage user = users[msg.sender];
        require(user.isExist, "User not registered yet");
        require(user.binaryAmount > 0, "No pool Activated");
        require(!user.isInBinary, "User Already added to binary");
        bytes memory pos = bytes(position);
        if (keccak256(pos) == keccak256("L")) {
            user.binaryPosition = 'L';
            user.isInBinary = true;
            return true;
        } else if (keccak256(pos) == keccak256("R")) {
            user.binaryPosition = 'R';
            user.isInBinary = true;
            return true;
        }
        
        return false;
    }

    function addUserInPool(
        uint256 _position,
        address _userAddress,
        uint256 _fee,
        uint256 _canEarn
    ) internal {
        PaymentList memory pList;
        pList = PaymentList({
            id: _position,
            userAddress: _userAddress,
            poolFee: _fee,
            canEarnMax: _canEarn,
            incomeAfterTopUp: 0,
            status: true,
            isBlocked: false
        });

        paymentList[_position] = pList;
    }

    function payPoolIncome(address _poolAddress, uint256 value) internal {
        uint256 totalTransactions = value / POOL_INCOME;
        
       
        for (uint256 i = 1; i <= totalTransactions; i++) {
            PaymentList storage _user = paymentList[poolStartFrom];

            uint256 _calculateIncome = _user.incomeAfterTopUp + POOL_INCOME;
            if (_calculateIncome <= _user.canEarnMax && !_user.isBlocked) {
                
                sendRewards(_user.userAddress, POOL_INCOME);
                
                _user.incomeAfterTopUp = _user.incomeAfterTopUp + POOL_INCOME;
              
                emit UserPoolIncome(
                    _user.userAddress,
                    _poolAddress,
                    POOL_INCOME,
                    _user.poolFee,
                    now
                );

                if (_user.incomeAfterTopUp == _user.canEarnMax) {
                    poolStartFrom++;
                    _user.isBlocked = true;
                }
            } 
        }
        currentPoolPosition++;
        poolList[currentPoolPosition] = _poolAddress;
    }
    
    function payBinaryIncome(address receiver, uint256 amount) external restricted {
        require(users[receiver].isExist, "User doesn't Exits");
        
        sendRewards(receiver, amount);
        
    }
    
    function sendRewards(address receiver, uint256 amount) internal {
        User storage user = users[receiver];
        if (user.id <= 20) {
            if (amount >= address(this).balance) {
                amount = address(this).balance;
                receiver.transfer(amount * 90/100);
                partner.transfer(amount * 10/100); //check before deploying
                emit BinaryIncome(receiver, amount);
            } else {
                receiver.transfer(amount * 90/100);
                partner.transfer(amount * 10/100);
                emit BinaryIncome(receiver, amount);
            }
        } else {
            if (amount >= address(this).balance) {
                amount = address(this).balance;
                receiver.transfer(amount);
                emit BinaryIncome(receiver, amount);
            } else {
                 receiver.transfer(amount);
                 emit BinaryIncome(receiver, amount);
            }
        }
        
    }

    function addInitUserWithPosition(
        uint256 _postion,
        address userAddress,
        address upline,
        uint256 level
    ) internal {
        uint256 refId = 0;
        refId = users[upline].id;
        address _teamOf;
        User memory user;
        //currentId++;
        user = User({
            isExist: true,
            id: _postion,
            referrerID: refId,
            referrer: address(0),
            referral: new address[](0),
           
            poolPosition: 0,
            poolFee: 0,
            binaryAmount: uint256(0),
            isInPool: false,
            isInBinary: false,
            binaryPosition: '0'
        });
        users[userAddress] = user;
        userList[_postion] = userAddress;
        users[userList[refId]].referral.push(userAddress);

       
    }

    function addInitUser(
        address userAddress,
        address upline,
        uint256 level
    ) internal {
        uint256 refId = 0;
        refId = users[upline].id;
        address _teamOf;
        User memory user;
        currentId++;
        user = User({
            isExist: true,
            id: currentId,
            referrerID: refId,
            referrer: address(0),
            referral: new address[](0),
           
            poolPosition: 0,
            poolFee: 0,
            binaryAmount: uint256(0),
            isInPool: true,
            isInBinary: false,
            binaryPosition: '0'
        });
        users[userAddress] = user;
        userList[currentId] = userAddress;
        users[userList[refId]].referral.push(userAddress);
       
    }

    function addUser(address upline, uint256 level) internal {
        uint256 refId = 0;
        refId = users[upline].id;
       
        User memory user;
        currentId++;
        user = User({
            isExist: true,
            id: currentId,
            referrerID: refId,
            referrer: upline,
            referral: new address[](0),
           
            poolPosition: 0,
            poolFee: 0,
            binaryAmount: uint256(0),
            isInPool: false,
            isInBinary: false,
            binaryPosition: '0'
           
        });
        users[msg.sender] = user;
        userList[currentId] = msg.sender;
        users[userList[refId]].referral.push(msg.sender);
    }
}