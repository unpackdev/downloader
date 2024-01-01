// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

// safe transfer.
// if is contract maybe is error. if account must success.
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
        (bool success,) = to.call{value:value}(new bytes(0));
        // (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// owner
abstract contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'owner error');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
}

// ReentrancyGuard.
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}


// Mining GODZ.
contract MiningGODZ is Ownable, ReentrancyGuard {
    using SafeMath for uint256;


    address public immutable gainToken;                             // gain token is GODZ.
    uint256 public constant DAY_SECOND_NUMBER = 86400;                 // mainnet=86400, testnet=60.
    uint256 public constant TAKE_END_TIME = DAY_SECOND_NUMBER * 3;  // 3 day can take.
    uint256 private constant SCALING_FACTOR = 1e18;                 // Scaling this up increases support for high supply tokens.
    uint256 public constant TOTAL_EARN = 600000000*(1e18);          // total earn.
    uint256[6] public EARN_RATIO = [30,20,10,20,15,5];              // earn ratio.
    uint256[6] public KEEP_TIME = [30*DAY_SECOND_NUMBER,20*DAY_SECOND_NUMBER,10*DAY_SECOND_NUMBER,30*DAY_SECOND_NUMBER,20*DAY_SECOND_NUMBER,10*DAY_SECOND_NUMBER];

    // pool info.
    struct PoolInfo {
        address token;              // token(only GODZ or GODZ-ETH-LP).
        uint256 startTime;          // start time.
        uint256 keepTime;           // mining time(10day/20day/30day).
        uint256 endTime;            // mining time(20day/40day/60day).
        uint256 amountPerTime;      // amount per time(keep time is 2mul time).
        uint256 totalEarn;          // total earn.
        uint256 totalDeposit;       // total deposit.
        uint256 accTokenPerShare;   // Accumulated Token per share, times SCALING_FACTOR. Check code.
        uint256 lastRewardTime;     // last reward time.
    }
    PoolInfo[] public poolInfo;        // pool info.

    // user info.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    struct UserInfo {
        uint256 startTime;          // start time.
        uint256 amount;             // depoist amount.
        uint256 rewardDebt;         // reward debt. Accumulated Token per share, times SCALING_FACTOR. Check code.
    }

    mapping(uint256 => mapping(address => address)) public inviter;    // pool id => account => super.
    mapping(address => bool) public whiteList;                         // white list.
    uint256 public inviterRatio = 10;                                  // 10%.
    uint256 public immutable whiteListPriorityTime;                    // white list priority 7 day.

    // user ids
    mapping(address => uint256[]) public userIDs;
    mapping(uint256 => IDInfoMsg) public IDInfo;      // ID => ID info.
    struct IDInfoMsg {
        uint256 pid;         // pid.
        uint256 ID;          // ID.
        uint256 depositTime; // deposit time.
        uint256 amount;      // amount.
        bool isTaked;        // is taked.
        address account;     // amount
    }
    uint256 public nextID = 0;  // next ID.


    constructor(address gainToken_, address lpToken_) {
        gainToken = gainToken_;
        _addAllPools(gainToken_, lpToken_);
        whiteListPriorityTime = DAY_SECOND_NUMBER.mul(7).add(block.timestamp);

        whiteList[msg.sender] = true;
    }

    event Deposit(uint256 pid, address account, uint256 amount, uint256 earn);
    event Withdraw(uint256 pid, uint256 ID, address account, uint256 amount);


    // add pools.
    function _addAllPools(address token_, address lp_) private {
        uint256 _count = EARN_RATIO.length;
        uint256 _startTime = block.timestamp;

        for(uint256 i = 0; i < _count; i++) {
            address _token = i < 3 ? lp_ : token_;
            poolInfo.push(PoolInfo({
            token: _token,
            startTime: _startTime,
            keepTime: KEEP_TIME[i],
            endTime: KEEP_TIME[i].mul(2).add(_startTime),
            amountPerTime: TOTAL_EARN.mul(EARN_RATIO[i]).div(100).div(KEEP_TIME[i]).div(2),
            totalEarn: TOTAL_EARN.mul(EARN_RATIO[i]).div(100),
            totalDeposit: 0,
            accTokenPerShare: 0,
            lastRewardTime: block.timestamp
            }));

            inviter[i][msg.sender] = msg.sender;
        }
    }

    // get all pool.
    function getAllPool() external view returns(PoolInfo[] memory) {
        return poolInfo;
    }

    // get user IDs.
    function getUserIDs(address account) external view returns(uint256[] memory) {
        return userIDs[account];
    }

    // get user IDs msg.
    function getUserIDsMsg(address account) external view returns(IDInfoMsg[] memory) {
        uint256 _length = userIDs[account].length;
        uint256[] memory _IDs = userIDs[account];
        IDInfoMsg[] memory _IDInfoMsgs = new IDInfoMsg[](_length);

        for(uint256 i = 0; i < _length; i++) {
            uint256 _ID = _IDs[i];
            _IDInfoMsgs[i] = IDInfo[_ID];
        }
        return _IDInfoMsgs;
    }
    
    receive() external payable {}

    function takeETH(address to, uint256 amount) external onlyOwner {
        require(amount > 0, "amount can not be 0");
        require(to != address(0), "invalid to address");
        TransferHelper.safeTransferETH(to, amount);
    }

    function takeToken(address token, address to, uint256 amount) external onlyOwner {
        require(to != address(0), "invalid to address");
        require(isContract(token), "token not contract");
        TransferHelper.safeTransfer(token, to, amount);
    }

    // set white list.
    function setWhiteList(address account, bool status) external onlyOwner {
        whiteList[account] = status;
    }

    // set white lists.
    function setWhiteLists(address[] memory accounts) external onlyOwner {
        uint256 _count = accounts.length;
        for(uint256 i = 0; i < _count; i++) {
            whiteList[accounts[i]] = true;
        }
    }

    // set inviter ratio.
    function setInviterRatio(uint256 newInviterRatio) external onlyOwner {
        require(newInviterRatio < 100, "number error");
        inviterRatio = newInviterRatio;
    }

    // _binding inviter.
    function _bindingInviter(uint256 pid, address account, address superAddress) private {
        require(!isContract(account), "is contract");
        require(superAddress != address(0), "zero address");
        require(superAddress != account, "not myself");
        require(inviter[pid][account] == address(0), "already binding");
        require(inviter[pid][superAddress] != address(0), "super not super");

        inviter[pid][account] = superAddress;
    }

    // update pool.
    function updatePool(uint256 pid) external {
        _updatePool(pid, 0);
    }

    function _updatePool(uint256 pid, uint256 amount) private {
        PoolInfo storage _PoolInfo = poolInfo[pid];

        if(block.timestamp <= _PoolInfo.lastRewardTime || _PoolInfo.totalDeposit == 0) {
            _PoolInfo.totalDeposit += amount;
            _PoolInfo.lastRewardTime = block.timestamp > _PoolInfo.endTime ? _PoolInfo.endTime : block.timestamp;
            return;
        }

        uint256 _timestamp = block.timestamp > _PoolInfo.endTime ? _PoolInfo.endTime : block.timestamp;
        uint256 _addPerShare = _timestamp.sub(_PoolInfo.lastRewardTime).mul(_PoolInfo.amountPerTime).mul(SCALING_FACTOR).div(_PoolInfo.totalDeposit);
        _PoolInfo.accTokenPerShare += _addPerShare;
        _PoolInfo.totalDeposit += amount;

        _PoolInfo.lastRewardTime = _timestamp;
    }

    // pending token.
    function pendingToken(uint256 pid, address account) public view returns(uint256) {
        PoolInfo memory _PoolInfo = poolInfo[pid];
        UserInfo memory _UserInfo = userInfo[pid][account];

        uint256 newAccTokenPerShare = _PoolInfo.accTokenPerShare;
        if(block.timestamp > _PoolInfo.lastRewardTime && _PoolInfo.totalDeposit != 0) {
            uint256 _timestamp = block.timestamp > _PoolInfo.endTime ? _PoolInfo.endTime : block.timestamp;
            uint256 addPerShare = _timestamp.sub(_PoolInfo.lastRewardTime).mul(_PoolInfo.amountPerTime).mul(SCALING_FACTOR).div(_PoolInfo.totalDeposit);
            newAccTokenPerShare += addPerShare;
        }
        uint256 pendingAmount = _UserInfo.amount.mul(newAccTokenPerShare).div(SCALING_FACTOR).sub(_UserInfo.rewardDebt);
        return pendingAmount;
    }

    // deposit.
    function deposit(uint256 pid, uint256 amount, address superAddress) external nonReentrant {
        PoolInfo storage _PoolInfo = poolInfo[pid];
        address account = msg.sender;
        // _binding inviter.
        if(inviter[pid][account] == address(0)) {
            _bindingInviter(pid, account, superAddress);
        }

        UserInfo storage _UserInfo = userInfo[pid][account];
        require(_PoolInfo.token != address(0), "zero address error");
        _updatePool(pid, amount);
        require(inviter[pid][account] != address(0), "not have super");
        require(whiteList[account] || block.timestamp > whiteListPriorityTime, "you are not white list");

        uint256 pendingAmount = 0;
        if(_UserInfo.amount > 0) {
            pendingAmount = _UserInfo.amount.mul(_PoolInfo.accTokenPerShare).div(SCALING_FACTOR).sub(_UserInfo.rewardDebt);
            if(pendingAmount > 0) {
                uint256 pendingAmountSuper = pendingAmount.mul(inviterRatio).div(100);
                uint256 pendingAmountMy = pendingAmount.sub(pendingAmountSuper);
                address _super = inviter[pid][account];
                if(userInfo[pid][_super].startTime > 0) {
                    if(pendingAmountSuper > 0) TransferHelper.safeTransfer(gainToken, _super, pendingAmountSuper);
                }
                if(pendingAmountMy > 0) TransferHelper.safeTransfer(gainToken, account, pendingAmountMy);
            }
        }
        if(amount > 0) {
            TransferHelper.safeTransferFrom(_PoolInfo.token, account, address(this), amount);
            _UserInfo.amount += amount;
            _UserInfo.startTime = block.timestamp;
            // add ID.
            nextID++;
            uint256 _ID = nextID;
            userIDs[account].push(_ID);
            IDInfo[_ID] = IDInfoMsg({
                pid: pid,
                ID: _ID,
                depositTime: block.timestamp,
                amount: amount,
                isTaked: false,
                account: account
            });
        }
        _UserInfo.rewardDebt = _UserInfo.amount.mul(_PoolInfo.accTokenPerShare).div(SCALING_FACTOR);
        emit Deposit(pid, account, amount, pendingAmount);
    }

    // withdraw.
    function withdraw(uint256 pid, uint256[] memory IDs) external nonReentrant {
        PoolInfo storage _PoolInfo = poolInfo[pid];
        address account = msg.sender;
        UserInfo storage _UserInfo = userInfo[pid][account];
        _updatePool(pid, 0);
        require(inviter[pid][account] != address(0), "not have super");
        require(whiteList[account] || block.timestamp > whiteListPriorityTime, "you are not white list");

        // earn.
        uint256 pendingAmount = _UserInfo.amount.mul(_PoolInfo.accTokenPerShare).div(SCALING_FACTOR).sub(_UserInfo.rewardDebt);
        if(pendingAmount > 0) {
            uint256 pendingAmountSuper = pendingAmount.mul(inviterRatio).div(100);
            uint256 pendingAmountMy = pendingAmount.sub(pendingAmountSuper);
            address _super = inviter[pid][account];
            if(userInfo[pid][_super].startTime > 0) { 
                if(pendingAmountSuper > 0) TransferHelper.safeTransfer(gainToken, _super, pendingAmountSuper);
            }
            if(pendingAmountMy > 0) TransferHelper.safeTransfer(gainToken, account, pendingAmountMy);
        }
        emit Deposit(pid, account, 0, pendingAmount);

        // take.
        uint256 _nowTime = block.timestamp;
        for(uint256 i = 0; i < IDs.length; i++) {
            uint256 _ID = IDs[i];
            IDInfoMsg storage _IDInfoMsg = IDInfo[_ID];
            require(!_IDInfoMsg.isTaked, "already taked");
            require(_IDInfoMsg.account == account, "ID not your");
            require(_IDInfoMsg.ID == _ID, "ID error");
            require(_IDInfoMsg.pid == pid, "pid error");

            uint256 _canTakeStartTime = _IDInfoMsg.depositTime.add(_PoolInfo.keepTime);
            uint256 _canTakeEndTime = _canTakeStartTime.add(TAKE_END_TIME);
            if((_nowTime >= _canTakeStartTime && _nowTime <= _canTakeEndTime) || _nowTime > _PoolInfo.endTime) {
                uint256 takedAmount = _IDInfoMsg.amount;
                if(takedAmount > 0) TransferHelper.safeTransfer(_PoolInfo.token, account, takedAmount);
                _UserInfo.amount -= takedAmount;
                _PoolInfo.totalDeposit -= takedAmount;

                _IDInfoMsg.isTaked = true;
                emit Withdraw(pid, _ID, account, takedAmount);
            }
        }

        _UserInfo.rewardDebt = _UserInfo.amount.mul(_PoolInfo.accTokenPerShare).div(SCALING_FACTOR);        
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

}