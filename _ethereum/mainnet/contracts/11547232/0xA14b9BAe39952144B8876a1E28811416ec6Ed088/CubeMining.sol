// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
import "./Initializable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract CubeMining is Ownable, Initializable {
    using SafeMath for uint256;
    mapping(address => mapping(uint256 => uint256)) private _users;
    /*
     internal mapping     
        "userId"           :  key->uint256 [0] => value->uint256 [amount]
        "userRefId"        :  key->uint256 [1] => value->uint256 [amount]
        "pledgeCda"        :  key->uint256 [2] => value->uint256 [amount]
        "pledgeUSDT"       :  key->uint256 [3] => value->uint256 [amount]
        "burnUSDT"         :  key->uint256 [4] => value->uint256 [amount]
        "reward"           :  key->uint256 [5] => value->uint256 [amount]
        "unclaimReward"    :  key->uint256 [6] => value->uint256 [amount]
        "lastCalcAt"       :  key->uint256 [7] => value->uint256 [amount]
        "addition"         :  key->uint256 [8] => value->uint256 [amount]
        "burnCDA"          :  key->uint256 [9] => value->uint256 [amount]
        "userPower"        :  key->uint256 [10] => value->uint256 [amount]
    */
    mapping(uint256 => address) private _userIdMap;
    mapping(uint256 => uint256) private _localUintVariables;
    /* _localUintVariables
    //0 uint256 private _userId; //current max userId
    //1 uint256 private _totalPledgeCda; //total pledge cda amount
    //2 uint256 private _totalPledgeUSDT; //total pledge usdt amount
    //3 uint256 private _miningHardCap; // mining max count of cda
    //4 uint256 private _initMiningPeriod; // the first mining period (30 days)
    //5 uint256 private _initMiningReward; // the first peroid mining reward
    //6 uint256 private _startAt; // the main contract start at
    //7 uint256 private _totalBurnCda; // total burn cda amount
    //8 uint256 private _cdaPrice; // the cda currency price
    //9 uint256 private _totalPledgeUSDTPower; //total pledge usdt computing power
    */

    mapping(uint256 => address) private _localAddressVariables;

    //_localAddressVariables
    //address private _cdaToken; // cda token contract address
    //address private _usdtToken; // usdt token contract address

    function initialize(
        address cdaToken,
        address usdtToken,
        uint256 miningHardCap,
        uint256 initMiningPeriod,
        uint256 initMiningReward
    ) public initializer {
        Ownable.initialize();
        _localUintVariables[0] = 100;
        _localAddressVariables[0] = cdaToken;
        _localAddressVariables[1] = usdtToken;
        _localUintVariables[3] = miningHardCap.mul(10**18);
        _localUintVariables[4] = initMiningPeriod * (1 days);
        _localUintVariables[5] = initMiningReward.mul(10**18);
        _localUintVariables[6] = block.timestamp;
    }

    event Addtion(
        string indexed ms,
        uint256 burnLevel,
        uint256 treeLevel,
        uint256 add,
        uint256 origin
    );

    //should approve before call this method
    function pledgeMining(
        uint256 cdaAmount,
        uint256 usdtAmount,
        uint256 refId
    ) external {
        //uint256 userId = _users[msg.sender][0];
        //address miningContract = address(this);
        //transfer cda and usdt to mining contract
        //cdaPrice = _localUintVariables[8]
        require(_localUintVariables[8] > 0, "cda price not update");
        uint256 cdaVal = cdaAmount.mul(_localUintVariables[8]).div(10000);
        require(usdtAmount.div(cdaVal) >= 5, "usdt should>=5*cdaVal");
        require(
            usdtAmount.div(cdaVal).mul(10) <= 51,
            "usdt should<=5.1*cdaVal"
        );
        require(
            IERC20(_localAddressVariables[0]).transferFrom(
                msg.sender,
                address(this),
                cdaAmount
            ) &&
                IERC20(_localAddressVariables[1]).transferFrom(
                    msg.sender,
                    address(this),
                    usdtAmount
                ),
            "transfer cda or usdt failed"
        );

        if (_users[msg.sender][0] == 0) {
            //起始Id是100
            require(
                (refId >= 100 && refId <= _localUintVariables[0]) ||
                    refId == 100000000,
                "invalid refId"
            );
            _localUintVariables[0] = _localUintVariables[0] + 1;
            _users[msg.sender][0] = _localUintVariables[0];
            _users[msg.sender][1] = refId;
            _userIdMap[_localUintVariables[0]] = msg.sender;
            //增加用户时，才需要增加算力
            //一级用户
            address level1Address = _userIdMap[refId];
            uint256 level1BurnLevel =
                getUserBurnLevel(_users[level1Address][4]);
            if (level1Address != address(0)) {
                //uint256 addition = getAddition(level1BurnLevel,1);

                emit Addtion(
                    "addtion",
                    level1BurnLevel,
                    1,
                    getAddition(level1BurnLevel, 1),
                    _users[level1Address][8]
                );
                _users[level1Address][8] = _users[level1Address][8].add(
                    getAddition(level1BurnLevel, 1)
                );
                updateUserPowerAndTotalPower(level1Address);
                //二级用户
                uint256 level2RefUserId = _users[level1Address][1];
                address level2Address = _userIdMap[level2RefUserId];
                uint256 level2BurnLevel =
                    getUserBurnLevel(_users[level2Address][4]);

                if (level2Address != address(0)) {
                    emit Addtion(
                        "addtion",
                        level2BurnLevel,
                        2,
                        getAddition(level2BurnLevel, 2),
                        _users[level2Address][8]
                    );
                    _users[level2Address][8] = _users[level2Address][8].add(
                        getAddition(level2BurnLevel, 2)
                    );
                    updateUserPowerAndTotalPower(level2Address);
                    //三级用户
                    uint256 level3RefUserId = _users[level2Address][1];
                    address level3Address = _userIdMap[level3RefUserId];
                    uint256 level3BurnLevel =
                        getUserBurnLevel(_users[level3Address][4]);
                    if (level3Address != address(0)) {
                        emit Addtion(
                            "addtion",
                            level3BurnLevel,
                            3,
                            getAddition(level3BurnLevel, 3),
                            _users[level3Address][8]
                        );
                        _users[level3Address][8] = _users[level3Address][8].add(
                            getAddition(level3BurnLevel, 3)
                        );
                        updateUserPowerAndTotalPower(level3Address);
                    }
                }
            }
        }
        _localUintVariables[1] = _localUintVariables[1].add(cdaAmount);
        _localUintVariables[2] = _localUintVariables[2].add(usdtAmount);
        _users[msg.sender][2] = _users[msg.sender][2].add(cdaAmount);
        _users[msg.sender][3] = _users[msg.sender][3].add(usdtAmount);
        updateUserPowerAndTotalPower(msg.sender);
    }

    function calcUserPower(address userAddress)
        internal
        view
        returns (uint256)
    {
        return
            _users[userAddress][3] //pledgeUSDT
                .mul(100 + _users[userAddress][8])
                .div(100)
                .add(_users[userAddress][4].div(2)); // burnUsdt
    }

    event UpdateUserPowerAndTotalPower(
        address indexed userAddr,
        uint256 power,
        uint256 addition
    );

    //更新用户算力和总算力值
    function updateUserPowerAndTotalPower(address userAddress) internal {
        uint256 newPower = calcUserPower(userAddress);
        uint256 crtAddition = newPower.sub(_users[userAddress][10]);
        _users[userAddress][10] = newPower;
        if (crtAddition > 0) {
            _localUintVariables[9] = _localUintVariables[9].add(crtAddition);
        }
        emit UpdateUserPowerAndTotalPower(userAddress, newPower, crtAddition);
    }

    //提取质押的代币（取回所有质押）
    function releasePledge() external {
        // uint256 cdaAmount = _users[msg.sender][2];
        // uint256 usdtAmount = _users[msg.sender][3];
        require(
            _users[msg.sender][2] > 0 && _users[msg.sender][3] > 0,
            "no pledge exist"
        );
        require(
            //transfer cda
            IERC20(_localAddressVariables[0]).transfer(
                msg.sender,
                _users[msg.sender][2]
            ),
            "transfer cda failed"
        );
        require(
            //transfer usdt
            IERC20(_localAddressVariables[1]).transfer(
                msg.sender,
                _users[msg.sender][3]
            ),
            "transfer usdt failed"
        );
        _localUintVariables[1] = _localUintVariables[1].sub(
            _users[msg.sender][2]
        );
        _localUintVariables[2] = _localUintVariables[2].sub(
            _users[msg.sender][3]
        );
        _localUintVariables[9] = _localUintVariables[9].sub(
            _users[msg.sender][10]
        );
        _users[msg.sender][2] = 0;
        _users[msg.sender][3] = 0;
        _users[msg.sender][10] = 0;
    }

    //提取奖励,继续质押
    function claimReward() external {
        uint256 cdaReward = _users[msg.sender][6];
        require(
            IERC20(_localAddressVariables[0]).balanceOf(address(this)) >=
                cdaReward,
            "exceed amount"
        );
        require(cdaReward > 1, "at least 1 cda can claim");
        require(
            IERC20(_localAddressVariables[0]).transfer(msg.sender, cdaReward),
            "transfer cda failed"
        );

        _users[msg.sender][6] = 0;
        _users[msg.sender][5] = _users[msg.sender][5].add(cdaReward);
    }

    //获取用户的燃烧信息
    function getBurnInfo(address userAddr) external view returns (uint256) {
        return _users[userAddr][4];
    }

    //获取用户燃烧等级
    function getUserBurnLevel(uint256 burnedUsdt)
        internal
        pure
        returns (uint256)
    {
        uint256 level;
        if (burnedUsdt < 200 * (10**18)) level = 0;
        if (burnedUsdt >= 200 * (10**18) && burnedUsdt < 500 * (10**18))
            level = 1;
        else if (burnedUsdt >= 500 * (10**18) && burnedUsdt < 800 * (10**18))
            level = 2;
        else if (burnedUsdt >= 800 * (10**18)) level = 3;
        return level;
    }

    //获得燃烧等级，层级对应的算力提升百分比

    function getAddition(uint256 burnLevel, uint256 treeLevel)
        internal
        pure
        returns (uint256)
    {
        require(treeLevel > 0, "tree level gte 1");
        require(burnLevel <= 3, "max level 3");
        uint256 basePercent;
        uint256 step;
        if (treeLevel == 1) {
            basePercent = 10;
            step = 5;
        } else if (treeLevel == 2) {
            basePercent = 5;
            step = 5;
        } else if (treeLevel == 3) {
            basePercent = 3;
            step = 2;
        }

        return basePercent.add(step.mul(burnLevel));
    }

    //燃烧提升算力，燃烧金额的一半直接附加在算力上（有质押的情况下）
    function burn(uint256 amount) external returns (bool) {
        //uint256 userId = _users[msg.sender][0];
        //uint256 cdaPrice = _localUintVariables[8];
        require(_localUintVariables[8] > 0, "price should gt 0");
        require(amount > 0, "amount should gt 0");
        require(_users[msg.sender][0] > 0, "invalid user cann't burn");
        //the price should div 10000(价格除以一万，意味着价格执行4位小数)
        uint256 usdtAmount = amount.mul(_localUintVariables[8]).div(10000);
        uint256 totalBurnUsdtAmount = usdtAmount.add(_users[msg.sender][4]);
        uint256 totalBurnCdaAmount = amount.add(_users[msg.sender][9]);
        require(totalBurnUsdtAmount <= 810 * 10**18, "exceed max burn amount");
        _users[msg.sender][4] = totalBurnUsdtAmount;
        _users[msg.sender][9] = totalBurnCdaAmount;
        if (_users[msg.sender][3] > 0) {
            //在有质押挖矿时，增加自身的算力
            updateUserPowerAndTotalPower(msg.sender);
        }
        _localUintVariables[7] = _localUintVariables[7].add(amount);
        return true;
    }

    event TestDebugLog(string mesg, uint256 val, uint256 addtime);
  
    // function calcMinerReward(
    //     address[] calldata userAddrs,
    //     uint256 addTimeHours 
    // )
    //     external
    //     onlyOwner
    //     returns (bool)
      function calcMinerReward(address[] calldata userAddrs)
    onlyOwner external
    returns (bool)
    {
        require(userAddrs.length <= 50, "too much address to calc");
        require(_localUintVariables[2] > 0, "no pledge");

        for (uint256 index = 0; index < userAddrs.length; index++) {
            //address userAddr = userAddrs[index];
            //uint256 userId = _users[userAddrs[index]][0];
            //uint256 addition = _users[userAddrs[index]][8];
            if (_users[userAddrs[index]][0] <= 0) continue;
            uint256 _now = block.timestamp;

            _now = block.timestamp; 
            //_now = block.timestamp.add(addTimeHours.mul(1 hours));
            if (_now.sub(_users[userAddrs[index]][7]) < 3 hours) continue;
            //第几个挖矿周期
            // uint256 periodCount = _now
            //     .sub(_localUintVariables[6]) // startAt
            //     .div(_localUintVariables[4]); // first mining period

            // periodCount = _now
            //     .sub(_localUintVariables[6]) // startAt
            //     .div(_localUintVariables[4]).add(1);

            uint256 periodCursor =
                _now
                    .sub(_localUintVariables[6]) // startAt
                    .div(_localUintVariables[4])
                    .add(1)
                    .srqt(2);
            emit TestDebugLog(
                "periodCursor",
                _now
                    .sub(_localUintVariables[6]) // startAt
                    .div(_localUintVariables[4])
                    .add(1),
                periodCursor
            );
            // calc reward, user should claim it manualy
            // uint unclaimReward = _users[userAddrs[index]][6];
            // uint reward = _users[userAddrs[index]][5];
            // uint256  totalPledgeUSDTPower = _localUintVariables[0];
            // uint256 pledgeUSDT = _users[userAddrs[index]][3];
            // uint256 initMiningReward =_localUintVariables[5];
            // 8 = 1 days * 24 / 3
            uint256 rewardAmount =
                _users[userAddrs[index]][10]
                    .mul(_localUintVariables[5].div(2**periodCursor))
                    .div(_localUintVariables[9]) //  total  pledge power
                    .div(8);

            _users[userAddrs[index]][6] = _users[userAddrs[index]][6].add(
                rewardAmount
            );

            //lastCalcAt
            _users[userAddrs[index]][7] = block.timestamp;
        }
        return true;
    }

    //获取用户信息
    function getUserInfo(address userAddr)
        external
        view
        returns (uint256[11] memory)
    //[0]  uint256, //userId
    //[1]  uint256, // userRefId
    //[2]  uint256, // pledgeCda
    //[3]  uint256, // pledgeUSDT
    //[4]  uint256, // burnUSDT
    //[5]  uint256, // reward
    //[6]  uint256, // unclaimReward
    //[7]  uint256, // lastCalcAt
    //[8]  uint256, // addition
    //[9]  uint256, // burnCDA
    //[10] uint256  // usdt power
    {
        return [
            _users[userAddr][0],
            _users[userAddr][1],
            _users[userAddr][2],
            _users[userAddr][3],
            _users[userAddr][4],
            _users[userAddr][5],
            _users[userAddr][6],
            _users[userAddr][7],
            _users[userAddr][8],
            _users[userAddr][9],
            _users[userAddr][10]
        ];
    }

    //获取用户信息
    function getUserAddress(uint256 userId) external view returns (address) {
        return _userIdMap[userId];
    }

    //获取挖矿统计信息
    function getStatisticsInfo()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _localUintVariables[2], //_totalPledgeUSDT
            _localUintVariables[7], //_totalBurnCda
            _localUintVariables[9], //_totalPledgeUSDT Power
            _localUintVariables[1] //_totalPledgeCda
        );
    }

    //更新cda价格，用户质押时USDT配比计算参照
    function updateCdaPrice(uint256 price) external onlyOwner {
        // real price mul 10000
        _localUintVariables[8] = price;
    }

    function getLocalUintVariable(uint256 index)
        external
        view
        returns (uint256)
    {
        require(index <= 9, "out of range");
        return _localUintVariables[index];
    }
}
