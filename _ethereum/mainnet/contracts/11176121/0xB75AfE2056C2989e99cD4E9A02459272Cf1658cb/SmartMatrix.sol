pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
}

// 智能矩阵
contract SmartMatrix {
    struct User {
        uint id;            // 用户ID
        uint8 level;        // 用户等级
        address payable referrer;       // 推荐人地址
        address payable[] referrals;    // 下级地址

        uint8[] dividendsType;    // 收益类型
        uint[]  dividendsAmount;  // 收益数量
        uint[]  dividendsTime;    // 收益时间

        uint[] upgradeTime;  // 升级时间
    }

    uint8 public constant _LAST_LEVEL = 16;     // 定义最高等级
    mapping(uint8 => uint) public _levelPrice;  // 每一等级的价格
    address payable public _owner;      // 合约拥有者地址

    mapping(address => User) public _users;     // 所有用户数据：地址——>用户数据
    mapping(uint => address payable) public _userIds;
    uint public lastUserId = 2;         // 最新的ID，目前为2
    
    using SafeMath for uint;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, uint8 level);

    constructor(address payable ownerAddress) public {
        // 初始化等级价格
        // 0.1  0.5  1  1.5  2  2.5   3   3.5   4   4.5   5   5.5   6   6.5   7   7.5       
        _levelPrice[1] = 0.1 ether;
        _levelPrice[2] = 0.5 ether;
        for (uint8 i = 3; i <= _LAST_LEVEL; i++) {
            _levelPrice[i] = _levelPrice[i-1] + 0.5 ether;
        }

        // 初始化用户数据
        User memory user = User({
            id: 1,                  // ID为1
            level: 16,
            referrer: address(0),   // 推荐人为空
            referrals: new address payable[](0),

            dividendsType: new uint8[](0),
            dividendsAmount: new uint[](0),
            dividendsTime: new uint[](0),
            upgradeTime: new uint[](0)
        });
        _users[ownerAddress] = user;
        _userIds[1] = ownerAddress;
        
        _owner = ownerAddress;       
    }

    receive() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, _owner);
        }
        registration(msg.sender, bytesToAddress(msg.data));
    }

    // 地址转换器
    function bytesToAddress(bytes memory bys) private pure returns (address payable addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function registrationExt(address payable referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }

    // 新用户注册：新用户地址、推荐人地址
    function registration(address payable userAddress, address payable referrerAddress) private {
        require(msg.value == 0.1 ether, "registration cost 0.1");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        // 计算新用户地址长度（大小）
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        // 如果长度（大小）为0，出错
        require(size == 0, "cannot be a contract");
        
        // 创建新用户对象
        User memory user = User({
            id: lastUserId,             // 新用户的ID为最新ID
            level: 1,
            referrer: referrerAddress,  // 推荐人地址为传入的推荐人地址
            referrals: new address payable [](0),
            
            dividendsType: new uint8[](0),
            dividendsAmount: new uint[](0),
            dividendsTime: new uint[](0),
            upgradeTime: new uint[](1)
        });
        user.upgradeTime[0] = block.timestamp;

        // 保存新用户数据：新用户地址——>新用户数据
        _users[userAddress] = user;

        // 把新用户地址记录到ID总册里，然后最新的ID+1，等待下一个新用户
        _userIds[lastUserId] = userAddress;
        lastUserId++;
        
        bool luck;
        uint res = _users[referrerAddress].referrals.length % 4; 
        if ( res == 0 || res == 1){
            luck = true;
        }

        _users[referrerAddress].referrals.push(userAddress);
        
        sendETH(referrerAddress, 1, luck);

        // 发送注册消息：新用户地址、推荐人地址、用户ID、用户推荐人ID
        emit Registration(userAddress, referrerAddress, _users[userAddress].id, _users[referrerAddress].id);
    }

    // 外用查询接口【查询用户是否注册】：输入用户地址；输出该用户是否存在
    function isUserExists(address payable user) public view returns (bool) {
        return (_users[user].id != 0);
    }

    // 购买新的等级
    function buyNewLevel(uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(msg.value == _levelPrice[level], "invalid price");
        require(level > 1 && level <= _LAST_LEVEL, "invalid level");

        require(_users[msg.sender].level < level, "level already activated");
        require(_users[msg.sender].level == level -1);  // 请先购买 level - 1

        _users[msg.sender].level = level;   // 升级
        _users[msg.sender].upgradeTime.push(block.timestamp);   // 记录升级时间


        bool luck;
        uint i = 0;
        for ( ; i < _users[_users[msg.sender].referrer].referrals.length; i++){
            if (_users[_users[msg.sender].referrer].referrals[i] == msg.sender){
                break;
            }
        }
        if (i % 4 == 0 || i % 4 == 1){
            luck = true;
        }

        sendETH(_users[msg.sender].referrer, level, luck);

        // 发送升级消息：用户地址、对应等级
        emit Upgrade(msg.sender, level);
    }

    function sendETH(address payable referrer, uint8 level, bool luck) private {
        if (luck && _users[referrer].level >= level) {
            uint fee = _levelPrice[level].div(10);
            uint dividend = _levelPrice[level].sub(fee);

            _owner.transfer(fee);
            transferDividends(referrer, dividend, 0);   // 0 直荐
        }else{
            sendETHDividends(referrer, level);      // 上6代内均分奖励
        }
    }

    function sendETHDividends(address payable referrer, uint8 level) private {
        address payable[] memory referrers = new address payable[](6);  // 获利地址, 最高6代
        uint  referrerid;           // 如果查找到创始人，则停止
        uint8 i = 0;
        for (; i < 6 && referrerid != 1; ) {
            if (_users[referrer].level >= level) {

                referrerid = _users[referrer].id;
                referrers[i] = referrer;    // 存入数组
                i++;
            }
            referrer = _users[referrer].referrer;   // 向上查找推荐人
        }

        uint  fee = _levelPrice[level].div(10); // 手续费
        uint  dividend = fee.mul(9).div(i);     // 每个地址，获得的利润

        _owner.transfer(fee);                   // 创始人获取 10% 手续费
        for (uint8 j = 0; j < i; j++){
            transferDividends(referrers[j], dividend, 1);  // 1 均分
        }
    }

    function transferDividends(address payable referrer, uint dividends, uint8 dividendsType) private {
        referrer.transfer(dividends);

        _users[referrer].dividendsType.push(dividendsType);
        _users[referrer].dividendsAmount.push(dividends);
        _users[referrer].dividendsTime.push(block.timestamp);
    }

    // 外用查询接口: 查询用户地址的信息
    function usersInfo(address payable userAddress) public view returns(uint, uint8, address) {
        return (_users[userAddress].id, _users[userAddress].level, _users[userAddress].referrer);
    }

    // 查询下级地址及其等级
    function getReferrals(address payable userAddress) public view returns(address payable[] memory, uint8[] memory) {
        uint8[] memory levels = new uint8[](_users[userAddress].referrals.length);
        for (uint i = 0; i < _users[userAddress].referrals.length; i++){
            levels[i] = _users[_users[userAddress].referrals[i]].level;
        }
        return (_users[userAddress].referrals, levels);
    }

    // 外用查询接口: 查询升级记录
    function upgradeInfo(address payable userAddress) public view returns(uint[] memory) {
        return _users[userAddress].upgradeTime;
    }

    // 查询收益记录
    function getDividends(address payable userAddress) public view returns(uint[] memory, uint8[] memory, uint[] memory, uint, uint) {
        uint teamNumber = 0;
        uint teamDividends = 0;

        (teamNumber, teamDividends) = getTeam(userAddress, teamNumber, teamDividends);
        return(_users[userAddress].dividendsTime, _users[userAddress].dividendsType, _users[userAddress].dividendsAmount, teamNumber, teamDividends);
    }

    function getTeam(address payable userAddress, uint teamNumber, uint teamDividends) private view returns(uint, uint){
        teamNumber = teamNumber + 1;
        for (uint i = 0; i < _users[userAddress].dividendsAmount.length; i++){
            teamDividends = teamDividends + _users[userAddress].dividendsAmount[i];
        }
        for (uint i = 0; i < _users[userAddress].referrals.length; i++){
            (teamNumber, teamDividends) = getTeam(_users[userAddress].referrals[i], teamNumber, teamDividends);
        }
        return (teamNumber, teamDividends);
    }
}