pragma solidity ^0.5.0;
/**
*英文名字，FSC
*🇨🇳中文名:【公平的智能合约】
*🏧游戏规则:游戏每轮投注统一使用ETH以太坊进出，币本位。（5天为一个周期）
 */
contract UtilFSC {

    uint ethWei = 1 ether;
    //    📶游戏分三个级别，投注金额分红和推广收益不同。
    //◾ V1级别(投注1-3个以太坊)
    //◾ V2级别(投注4-6个以太坊)
    //◾ V3级别(投注7-10个以太坊)
    function getLevel(uint value, uint _type) public view returns (uint) {
        if (value >= 1 * ethWei && value <= 3 * ethWei) return 1;
        if (value >= 4 * ethWei && value <= 6 * ethWei) return 2;
        if (_type == 1 && value >= 7 * ethWei) return 3;
        else if (_type == 2 && value >= 7 * ethWei && value <= 10 * ethWei) return 3;
        return 0;
    }
    //Ⓜ️每日分红
    //V1每天收益为1%
    //V2每天收益为1.1%
    //V3每天收益为1.2%
    function getScByLevel(uint level) public pure returns (uint) {
        if (level == 1) return 10;
        if (level == 2) return 11;
        if (level == 3) return 12;
        return 0;
    }
    //❶完美的小推大烧伤机制。
    //奖励烧伤：自己账户金额除以15为烧伤基数。
    //不同等级有不同烧伤系数，
    //V1为30%，
    //V2为60%，
    //V3为100%，
    //例如：A推荐B，A入股 5ETH，B入股15ETH，则A每日得到的奖金为（15*1/100）*50%*5/15*30% 。
    //如果B先投注，则A在未来7天奖励发放时都得不到B的推 荐奖励。
    function getFireScByLevel(uint level) public pure returns (uint) {
        if (level == 1) return 3;
        if (level == 2) return 6;
        if (level == 3) return 10;
        return 0;
    }

    //Ⓜ️ 推广奖励
    //  🔘 V1拿第1代收益的50%
    //第2代收益的30%
    //第3代收益的20%
    //第4代收益的10%
    //第5代收益的10%
    //    🔘 V2拿第1代收益的50%
    //        拿第2代收益的30%
    //        第3代收益的20%
    //        第4—10代收益的10%
    //🔘 V3拿第1代收益的70%
    //          拿第2代收益的30%
    //          拿第3代收益的20%
    //          拿第4-10代收益的10%
    //          拿第11-20代收益15%
    //          拿第21到-无限代1%

    //            V1推荐3人拿5代。
    //           V2 推荐5人拿10代。
    //           V3 推荐1人拿1代 。
    //            推荐5人拿5代。
    //                 以此类推……
    //            推荐9人拿9代。
    //            推荐10人即可拿无限代。
    //        投资级别和直推人数决定了自己动态奖金的深度。
    function getRecommendScaleByLevelAndTim(uint level, uint times) public pure returns (uint){
        if (level == 1) {
            if (times == 1) return 50;
            if (times == 2) return 30;
            if (times == 3) return 20;
            if (times == 4) return 10;
            if (times == 5) return 10;
        }
        if (level == 2) {
            if (times == 1) return 50;
            if (times == 2) return 30;
            if (times == 3) return 20;
            if (times >= 4 && times <= 10) return 10;
        }
        if (level == 3) {
            if (times == 1) return 70;
            if (times == 2) return 30;
            if (times == 3) return 20;
            if (times >= 4 && times <= 10) return 10;
            if (times >= 11 && times <= 20) return 15;
            //            > 10 代  1%
            if (times >= 21) return 1;
        }
        return 0;
    }

    function compareStr(string memory _str, string memory str) public pure returns (bool) {
        if (keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str))) return true;
        return false;
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {

    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {

    address private _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {

    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context, Ownable {

    using Roles for Roles.Role;

    Roles.Role private _whitelistAdmins;

    constructor () internal {
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()) || isOwner(), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account) || isOwner();
    }

    function addWhitelistAdmin(address account) public onlyOwner {
        _whitelistAdmins.add(account);
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _whitelistAdmins.remove(account);
    }
}

contract FSC is UtilFSC, WhitelistAdminRole {

    using SafeMath for *;
    uint ethWei = 1 ether;
    //    FSC合约收益地址
    address payable private devAddr = address(0x445042C0e21855cC7A32299302f7F1085a5d447C);
    //    address payable private devAddr = address(0x6A70363e19A0301D42698159b985bA91C7f6f802);
    //    FSC合约慈善基金10%
    address payable private comfortAddr = address(0xe0d2beD8fddcFC27962baa3450e77430163f37E7);
    //    address payable private comfortAddr = address(0x849f948Fbb1D7B8791acF8638724679fcF8B21Ef);
    //    前提现有个10%
    //的手续费扣除
    address payable private feeAddr = address(0x68D1219A571466e2ab346A43A1dcA986201b4584);
    //    address payable private feeAddr = address(0xf199378b6026b8141e77964A9e57cA35597ffB84);
    //   当前账户余额,每天结算时候,清算一次,
    uint public currBalance = 0 ether;
    uint curr = 0 ether;
    uint _time = now;

    struct User {
        uint id;
        address userAddress;
        uint freeAmount;
        uint freezeAmount;
        uint lineAmount;
        uint inviteAmonut;
        uint dayBonusAmount;
        uint bonusAmount;
        uint level;
        uint lineLevel;
        uint resTime;
        uint investTimes;
        string inviteCode;
        string beCode;
        uint rewardIndex;
        uint lastRwTime;
        //        大周期
        uint bigCycle;
    }

    struct UserGlobal {
        uint id;
        address userAddress;
        string inviteCode;
        string beCode;
        uint status;
    }

    struct AwardData {
        uint oneInvAmount;
        uint twoInvAmount;
        uint threeInvAmount;
    }

    uint lineStatus = 0;
    mapping(uint => uint) rInvestCount;
    mapping(uint => uint) rInvestMoney;
    uint period = 1 days;
    uint uid = 0;
    uint rid = 1;
    mapping(uint => uint[]) lineArrayMapping;
    mapping(uint => mapping(address => User)) userRoundMapping;
    mapping(address => UserGlobal) userMapping;
    mapping(string => address) addressMapping;
    mapping(uint => address) indexMapping;
    mapping(uint => mapping(address => mapping(uint => AwardData))) userAwardDataMapping;
    uint bonuslimit = 10 ether;
    uint sendLimit = 100 ether;
    uint withdrawLimit = 10 ether;
    uint canImport = 1;
    //    小周期 天数
    uint smallCycle = 5;
    //    uint smallCycle = 2;

    uint jiangeTime = 12 hours;
    //    uint jiangeTime = 12 seconds;

    modifier isHuman() {
        address addr = msg.sender;
        uint codeLength;
        assembly {codeLength := extcodesize(addr)}
        require(codeLength == 0, "sorry humans only");
        require(tx.origin == msg.sender, "sorry, humans only");
        _;
    }

    constructor () public {
    }

    function() external payable {
    }

    function updateLine(uint line, uint small) external onlyWhitelistAdmin {
        lineStatus = line;
        smallCycle = small;
    }

    function isLine() private view returns (bool) {
        return lineStatus != 0;
    }

    //    del
    function actAllLimit(uint bonusLi, uint sendLi, uint withdrawLi) external onlyOwner {
        require(bonusLi >= 15 ether && sendLi >= 100 ether && withdrawLi >= 15 ether, "invalid amount");
        bonuslimit = bonusLi;
        sendLimit = sendLi;
        withdrawLimit = withdrawLi;
    }

    function stopImport() external onlyOwner {
        canImport = 0;
    }

    function actUserStatus(address addr, uint status) external onlyWhitelistAdmin {
        require(status == 0 || status == 1 || status == 2, "bad parameter status");
        UserGlobal storage userGlobal = userMapping[addr];
        userGlobal.status = status;
    }
    //   加权
    function repeatPldge() public {

        User storage user = userRoundMapping[rid][msg.sender];
        require(user.investTimes >= smallCycle, "investTimes must more than 5");
        user.bigCycle += 1;
        require(user.id != 0, "user not exist");
        uint resultMoney = user.freeAmount + user.lineAmount;

        user.freeAmount = 0;
        user.lineAmount = 0;
        user.lineLevel = getLevel(user.freezeAmount, 1);

        require(resultMoney >= 1 * ethWei && resultMoney <= 10 * ethWei, "between 1 and 10");

        uint investAmout;
        uint lineAmount;
        if (isLine()) lineAmount = resultMoney;
        else investAmout = resultMoney;
        require(user.freezeAmount.add(user.lineAmount) == 0, "only once invest");
        user.freezeAmount = investAmout;
        user.lineAmount = lineAmount;
        user.level = getLevel(user.freezeAmount, 2);
        user.lineLevel = getLevel(user.freezeAmount.add(user.freeAmount).add(user.lineAmount), 1);

        rInvestCount[rid] = rInvestCount[rid].add(1);
        rInvestMoney[rid] = rInvestMoney[rid].add(resultMoney);
        if (!isLine()) {
            sendFeetoAdmin(resultMoney);
            countBonus(user.userAddress);
        } else lineArrayMapping[rid].push(user.id);


    }

    function exit(string memory inviteCode, string memory beCode) public isHuman() payable {

        require(msg.value >= 1 * ethWei && msg.value <= 10 * ethWei, "between 1 and 10");
        require(msg.value == msg.value.div(ethWei).mul(ethWei), "invalid msg value");

        UserGlobal storage userGlobal = userMapping[msg.sender];
        if (userGlobal.id == 0) {
            require(!compareStr(inviteCode, "") && bytes(inviteCode).length == 6, "invalid invite code");
            address beCodeAddr = addressMapping[beCode];
            require(isUsed(beCode), "beCode not exist");
            require(beCodeAddr != msg.sender, "beCodeAddr can't be self");
            require(!isUsed(inviteCode), "invite code is used");
            registerUser(msg.sender, inviteCode, beCode);
        }
        uint investAmout;
        uint lineAmount;
        if (isLine()) lineAmount = msg.value;
        else investAmout = msg.value;
        User storage user = userRoundMapping[rid][msg.sender];
        if (user.id != 0) {
            require(user.freezeAmount.add(user.lineAmount) == 0, "only once invest");
            user.freezeAmount = investAmout;
            user.lineAmount = lineAmount;
            user.level = getLevel(user.freezeAmount, 2);
            user.lineLevel = getLevel(user.freezeAmount.add(user.freeAmount).add(user.lineAmount), 1);
        } else {
            user.id = userGlobal.id;
            user.userAddress = msg.sender;
            user.freezeAmount = investAmout;
            user.level = getLevel(investAmout, 2);
            user.lineAmount = lineAmount;
            user.lineLevel = getLevel(user.freezeAmount.add(user.freeAmount).add(user.lineAmount), 1);
            user.inviteCode = userGlobal.inviteCode;
            user.beCode = userGlobal.beCode;
        }

        rInvestCount[rid] = rInvestCount[rid].add(1);
        rInvestMoney[rid] = rInvestMoney[rid].add(msg.value);
        if (!isLine()) {
            sendFeetoAdmin(msg.value);
            countBonus(user.userAddress);
        } else lineArrayMapping[rid].push(user.id);
    }

    function importGlobal(address addr, string calldata inviteCode, string calldata beCode) external onlyWhitelistAdmin {
        require(canImport == 1, "import stopped");
        UserGlobal storage user = userMapping[addr];
        require(user.id == 0, "user already exists");
        require(!compareStr(inviteCode, ""), "empty invite code");
        if (uid != 0) require(!compareStr(beCode, ""), "empty beCode");
        address beCodeAddr = addressMapping[beCode];
        require(beCodeAddr != addr, "beCodeAddr can't be self");
        require(!isUsed(inviteCode), "invite code is used");

        registerUser(addr, inviteCode, beCode);
    }

    //    del
    function helloworld(uint start, uint end, uint isUser) external onlyWhitelistAdmin {
        for (uint i = start; i <= end; i++) {
            uint userId = 0;
            if (isUser == 0) userId = lineArrayMapping[rid][i];
            else userId = i;
            address userAddr = indexMapping[userId];
            User storage user = userRoundMapping[rid][userAddr];
            if (user.freezeAmount == 0 && user.lineAmount >= 1 ether && user.lineAmount <= 10 ether) {
                user.freezeAmount = user.lineAmount;
                user.level = getLevel(user.freezeAmount, 2);
                user.lineAmount = 0;
                sendFeetoAdmin(user.freezeAmount);
                countBonus(user.userAddress);
            }
        }
    }

    function countBonus(address userAddr) private {
        User storage user = userRoundMapping[rid][userAddr];
        if (user.id == 0) return;
        uint scale = getScByLevel(user.level);
        user.dayBonusAmount = user.freezeAmount.mul(scale).div(1000);
        user.investTimes = 0;
        UserGlobal memory userGlobal = userMapping[userAddr];
        if (user.freezeAmount >= 1 ether && user.freezeAmount <= bonuslimit && userGlobal.status == 0) getaway(user.beCode, user.freezeAmount, scale);

    }

    function getaway(string memory beCode, uint money, uint shareSc) private {
        string memory tmpReferrer = beCode;

        for (uint i = 1; i <= 25; i++) {
            if (compareStr(tmpReferrer, "")) break;
            address tmpUserAddr = addressMapping[tmpReferrer];
            UserGlobal storage userGlobal = userMapping[tmpUserAddr];
            User storage calUser = userRoundMapping[rid][tmpUserAddr];

            if (calUser.freezeAmount.add(calUser.freeAmount).add(calUser.lineAmount) == 0) {
                tmpReferrer = userGlobal.beCode;
                continue;
            }

            uint recommendSc = getRecommendScaleByLevelAndTim(3, i);
            uint moneyResult = 0;
            if (money <= 10 ether) moneyResult = money;
            else moneyResult = 10 ether;

            if (recommendSc != 0) {
                uint tmpDynamicAmount = moneyResult.mul(shareSc).mul(recommendSc);
                tmpDynamicAmount = tmpDynamicAmount.div(1000).div(100);
                earneth(userGlobal.userAddress, tmpDynamicAmount, calUser.rewardIndex, i);
            }
            tmpReferrer = userGlobal.beCode;
        }
    }

    function earneth(address userAddr, uint dayInvAmount, uint rewardIndex, uint times) private {
        for (uint i = 0; i < smallCycle; i++) {
            AwardData storage awData = userAwardDataMapping[rid][userAddr][rewardIndex.add(i)];
            if (times == 1) awData.oneInvAmount += dayInvAmount;
            if (times == 2) awData.twoInvAmount += dayInvAmount;
            awData.threeInvAmount += dayInvAmount;
        }
    }

    function happy() public isHuman() {

        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id != 0, "user not exist");
        uint sendMoney = user.freeAmount + user.lineAmount;

        bool isEnough = false;
        uint resultMoney = 0;
        uint resultMoney1 = 0;
        (isEnough, resultMoney) = isEnoughBalance(sendMoney);
        //❷5天一轮结束后，自由选择，可以选择复投，可以选择离开，离开扣10%手续费，10轮后离开不扣手续费
        if (user.bigCycle < 10) resultMoney1 = resultMoney.mul(9).div(10);
        if (resultMoney1 > 0 && resultMoney1 <= withdrawLimit) {
            sendMoneyToUser(msg.sender, resultMoney1);
            user.freeAmount = 0;
            user.lineAmount = 0;
            user.bigCycle = 0;
            user.lineLevel = getLevel(user.freezeAmount, 1);
        }
        //        手续费15/100扣除
        if (user.bigCycle < 10) sendMoneyToUser(feeAddr, resultMoney.mul(15).div(100));
    }

    function christmas(uint start, uint end) external onlyWhitelistAdmin {

        if (_time - now > jiangeTime) {
            if (address(this).balance > curr) currBalance = address(this).balance.sub(curr);
            else currBalance = 0 ether;
            curr = address(this).balance;
        }
        for (uint i = start; i <= end; i++) {
            address userAddr = indexMapping[i];
            User storage user = userRoundMapping[rid][userAddr];
            UserGlobal memory userGlobal = userMapping[userAddr];
            if (now.sub(user.lastRwTime) <= jiangeTime) {
                continue;
            }
            uint bonusSend = 0;
            //              为了奖励全球忠实粉丝，对于V2级别以上玩家，做出如下奖励：
            //▪️ 凡参与11轮(含11轮)以上的拿全球当日新增业绩的1%加权分红。
            //▪️ 凡参与20轮以上的拿全球当日新增存币的2%加权分红。
            //▪️ 凡参与30轮以上的拿全球当日新增业绩的3%的加权分红。
            if (user.level >= 2) {
                uint inviteSendQ = 0;
                if (user.bigCycle >= 10 && user.bigCycle < 20) inviteSendQ = currBalance.div(100);
                else if (user.bigCycle >= 20 && user.bigCycle < 30) inviteSendQ = currBalance.div(50);
                else if (user.bigCycle >= 30) inviteSendQ = currBalance.div(100).mul(3);


                bool isEnough = false;
                uint resultMoneyQ = 0;
                (isEnough, resultMoneyQ) = isEnoughBalance(bonusSend.add(inviteSendQ));
                if (resultMoneyQ > 0) {
                    address payable sendAddr = address(uint160(userAddr));
                    sendMoneyToUser(sendAddr, resultMoneyQ);
                }
            }
            user.lastRwTime = now;
            if (userGlobal.status == 1) {
                user.rewardIndex = user.rewardIndex.add(1);
                continue;
            }

            if (user.id != 0 && user.freezeAmount >= 1 ether && user.freezeAmount <= bonuslimit) {
                if (user.investTimes < smallCycle) {
                    bonusSend += user.dayBonusAmount;
                    user.bonusAmount = user.bonusAmount.add(bonusSend);
                    user.investTimes = user.investTimes.add(1);
                } else {
                    user.freeAmount = user.freeAmount.add(user.freezeAmount);
                    user.freezeAmount = 0;
                    user.dayBonusAmount = 0;
                    user.level = 0;
                }
            }
            uint lineAmount = user.freezeAmount.add(user.freeAmount).add(user.lineAmount);
            if (lineAmount < 1 ether || lineAmount > withdrawLimit) {
                user.rewardIndex = user.rewardIndex.add(1);
                continue;
            }
            uint inviteSend = 0;
            if (userGlobal.status == 0) {
                AwardData memory awData = userAwardDataMapping[rid][userAddr][user.rewardIndex];
                user.rewardIndex = user.rewardIndex.add(1);
                uint lineValue = lineAmount.div(ethWei);
                if (lineValue >= 15) {
                    inviteSend += awData.threeInvAmount;
                } else {
                    if (user.lineLevel == 1 && lineAmount >= 1 ether && awData.oneInvAmount > 0) inviteSend += awData.oneInvAmount.div(15).mul(lineValue).div(2);

                    if (user.lineLevel == 2 && lineAmount >= 6 ether && (awData.oneInvAmount > 0 || awData.twoInvAmount > 0)) {
                        inviteSend += awData.oneInvAmount.div(15).mul(lineValue).mul(7).div(10);
                        inviteSend += awData.twoInvAmount.div(15).mul(lineValue).mul(5).div(7);
                    }
                    if (user.lineLevel == 3 && lineAmount >= 11 ether && awData.threeInvAmount > 0) inviteSend += awData.threeInvAmount.div(15).mul(lineValue);

                    if (user.lineLevel < 3) {
                        uint fireSc = getFireScByLevel(user.lineLevel);
                        inviteSend = inviteSend.mul(fireSc).div(10);
                    }
                }
            } else if (userGlobal.status == 2) user.rewardIndex = user.rewardIndex.add(1);

            if (bonusSend.add(inviteSend) <= sendLimit) {
                user.inviteAmonut = user.inviteAmonut.add(inviteSend);
                bool isEnough = false;
                uint resultMoney = 0;
                (isEnough, resultMoney) = isEnoughBalance(bonusSend.add(inviteSend));
                if (resultMoney > 0) {
                    uint confortMoney = resultMoney.div(10);
                    sendMoneyToUser(comfortAddr, confortMoney);
                    resultMoney = resultMoney.sub(confortMoney);
                    address payable sendAddr = address(uint160(userAddr));
                    sendMoneyToUser(sendAddr, resultMoney);
                }
            }

        }

        _time = now;
    }

    function isEnoughBalance(uint sendMoney) private view returns (bool, uint){
        if (sendMoney >= address(this).balance) return (false, address(this).balance);
        else return (true, sendMoney);
    }
    //    📌技术开发及维护费
    //      投注金额的5%，会自动划拨到专用账户，3%用于技术开发和维护，1% 用于生态发展与基础建设，1%用于创始团队开发市场。95%返补市场进入游戏分红。分红按实际投资金额分红。
    // 投注金额的5%，会自动划拨到专用账户
    function sendFeetoAdmin(uint amount) private {
        //        5% 专用账户
        devAddr.transfer(amount.div(20));
    }
    //1%用于创始团队开发市场
    function sendMoneyToUser(address payable userAddress, uint money) private {
        if (money > 0) userAddress.transfer(money);
    }

    function isUsed(string memory code) public view returns (bool) {
        address addr = addressMapping[code];
        return uint(addr) != 0;
    }

    function getUserAddressByCode(string memory code) public view returns (address) {
        require(isWhitelistAdmin(msg.sender), "Permission denied");
        return addressMapping[code];
    }

    function registerUser(address addr, string memory inviteCode, string memory beCode) private {
        UserGlobal storage userGlobal = userMapping[addr];
        uid++;
        userGlobal.id = uid;
        userGlobal.userAddress = addr;
        userGlobal.inviteCode = inviteCode;
        userGlobal.beCode = beCode;

        addressMapping[inviteCode] = addr;
        indexMapping[uid] = addr;
    }

    function donnottouch() public view returns (uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        return (
        rid,
        uid,
        now,
        rInvestCount[rid],
        rInvestMoney[rid],
        bonuslimit,
        sendLimit,
        withdrawLimit,
        canImport,
        lineStatus,
        lineArrayMapping[rid].length,
        1
        );
    }

    function getUserByAddress(address addr, uint roundId) public view returns (uint[15] memory info, string memory inviteCode, string memory beCode) {
        require(isWhitelistAdmin(msg.sender) || msg.sender == addr, "Permission denied for view user's privacy");

        if (roundId == 0) roundId = rid;

        UserGlobal memory userGlobal = userMapping[addr];
        User memory user = userRoundMapping[roundId][addr];
        info[0] = userGlobal.id;
        info[1] = user.lineAmount;
        info[2] = user.freeAmount;
        info[3] = user.freezeAmount;
        info[4] = user.inviteAmonut;
        info[5] = user.bonusAmount;
        info[6] = user.lineLevel;
        info[7] = user.dayBonusAmount;
        info[8] = user.rewardIndex;
        info[9] = user.investTimes;
        info[10] = user.level;
        uint grantAmount = 0;
        if (user.id > 0 && user.freezeAmount >= 1 ether && user.freezeAmount <= bonuslimit && user.investTimes < 7 && userGlobal.status != 1) grantAmount += user.dayBonusAmount;

        if (userGlobal.status == 0) {
            uint inviteSend = 0;
            AwardData memory awData = userAwardDataMapping[rid][user.userAddress][user.rewardIndex];
            uint lineAmount = user.freezeAmount.add(user.freeAmount).add(user.lineAmount);
            if (lineAmount >= 1 ether) {
                uint lineValue = lineAmount.div(ethWei);
                if (lineValue >= 15) inviteSend += awData.threeInvAmount;
                else {
                    if (user.lineLevel == 1 && lineAmount >= 1 ether && awData.oneInvAmount > 0) inviteSend += awData.oneInvAmount.div(15).mul(lineValue).div(2);

                    if (user.lineLevel == 2 && lineAmount >= 1 ether && (awData.oneInvAmount > 0 || awData.twoInvAmount > 0)) {
                        inviteSend += awData.oneInvAmount.div(15).mul(lineValue).mul(7).div(10);
                        inviteSend += awData.twoInvAmount.div(15).mul(lineValue).mul(5).div(7);
                    }
                    if (user.lineLevel == 3 && lineAmount >= 1 ether && awData.threeInvAmount > 0) inviteSend += awData.threeInvAmount.div(15).mul(lineValue);

                    if (user.lineLevel < 3) {
                        uint fireSc = getFireScByLevel(user.lineLevel);
                        inviteSend = inviteSend.mul(fireSc).div(10);
                    }
                }
                grantAmount += inviteSend;
            }
        }
        info[11] = grantAmount;
        info[12] = user.lastRwTime;
        info[13] = userGlobal.status;
        info[14] = user.bigCycle;

        return (info, userGlobal.inviteCode, userGlobal.beCode);
    }

    function getUserAddressById(uint id) public view returns (address) {
        require(isWhitelistAdmin(msg.sender), "Permission denied");
        return indexMapping[id];
    }

    function getLineUserId(uint index, uint rouId) public view returns (uint) {
        require(isWhitelistAdmin(msg.sender), "Permission denied");
        if (rouId == 0) rouId = rid;
        return lineArrayMapping[rid][index];
    }
}

/**
* @title SafeMath
* @dev Math operations with safety checks that revert on error
*/
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) return 0;

        uint256 c = a * b;
        require(c / a == b, "mul overflow");

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div zero");
        // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "lower sub bigger");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "overflow");

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "mod zero");
        return a % b;
    }

    /**
    * @dev compare two numbers and returns the smaller one.
    */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }
}