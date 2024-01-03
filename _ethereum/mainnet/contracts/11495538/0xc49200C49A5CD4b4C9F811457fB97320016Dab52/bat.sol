pragma solidity ^0.4.24;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract IERC20 {
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns
    (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns
    (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256
    _value);
    event TransferFrom(address indexed _from, address indexed _to, uint256 _value);

    function mintInvest(address from, address to, uint256 value) public;

    function burnInvest(address from, uint256 value) public;

}


contract IUNIGame {
    function transferTokenV(uint256 _v) public;
}

contract bat {
    using SafeMath for uint256;
    event Created(address indexed _from, address indexed _to, uint256 _value);

    struct Order {
        address addr;
        uint256 amount;
        uint256 startTime;
        uint256 bonusAmount;
        bool isEnd;
        uint256 withdrawn;

    }


    struct User {
        address upAddr;
        uint256 checkPoint;
        uint256 investAmount;
        uint256 poolBonus;
        uint256 dyBonus;
        uint256 smBonus;
        bool used;
        uint256[] orderIndexArr;
        address[] playerArr;
        mapping(uint256 => uint256) teamInvestMap;

        uint256 smRewardsAmount;
        uint256 smInvestAmount;
    }

    struct SortBean {
        address addr;
        uint256 value;
    }

    uint256 ONE_DAY = 1 days;

    //TODO 
    address tokenAddr = 0x5A947A3e5B62Cb571C056eC28293b32126E4d743;//
    uint256 ONE_TOKEN = 1 * 10 ** 18;//
    address foundationAddr = 0x4FE86109DB7B0fA397bF15E3d667A7B440725EaF;//
    address devAddr = 0x0000000000000000000000000000000000000000;//
    address lpGameAddr = 0xF4a7f38aF76041e4C75a5eCFf590d502A5B5AEa1;//
    address ethRecAddr = 0xDeDac392ff406836Aa945d8C8d3420F0357cdBC7;//
    //TODO 


    address owner;//

    Order[] orderArr;
    mapping(address => User) userMap;
    address[]userArr;

    uint256 smTotal;
    uint256 investTotal;
    uint256 bonusPoolAmount;


    uint256 gameStartTime;

    uint256 settlementTime;



    constructor(uint256 beginTime)public{
        owner = msg.sender;
        emit Created(msg.sender, address(this), now);
        if (beginTime == 0) {
            gameStartTime = now;
            settlementTime = now;
        } else {
            gameStartTime = beginTime;
            settlementTime = beginTime;
        }
        User storage user = userMap[owner];
        user.used = true;
        userArr.push(owner);

    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }



    function showTimes() public view returns (uint256, uint256, uint256){
        return (gameStartTime, 0, 0);
    }


    function checkUpAddr(address _upAddr) internal {
        if (userMap[msg.sender].upAddr == address(0)) {
            if (userMap[_upAddr].used) {
                userMap[msg.sender].upAddr = _upAddr;
            } else {
                userMap[msg.sender].upAddr = owner;
            }

            userMap[userMap[msg.sender].upAddr].playerArr.push(msg.sender);
            userArr.push(msg.sender);
            userMap[msg.sender].used = true;
        }
    }

    function testInvestEvent(uint256 _value) internal {
        IERC20 token = IERC20(tokenAddr);
        token.mintInvest(address(this), foundationAddr, _value * 15 / 1000);
        token.mintInvest(address(this), devAddr, _value * 15 / 1000);
        token.mintInvest(address(this), lpGameAddr, _value * 51 / 100);
        IUNIGame uni = IUNIGame(lpGameAddr);
        uni.transferTokenV(_value * 51 / 100);
    }


    function testsm(address _addr) public payable {
        (uint256 curRound,,) = getRound();
        require(curRound != 0, "time not");
        require(curRound < 4, " time end ");
        uint256 tempValue = 1 ether / 10;
        require(msg.value >= tempValue, "more 0.1");
        require(msg.value % tempValue == 0, "0.1 multiples");


        {
            uint256 smRe;
            uint256 smInv;
            (smRe, smInv) = getSmRealTokenAmount333(curRound, msg.value);
            User storage user = userMap[msg.sender];
            user.smRewardsAmount += smRe;
            user.smInvestAmount += smInv;
        }
        //
        checkUpAddr(_addr);
        smTotal += msg.value;
        ethRecAddr.transfer(msg.value);
    }

    function withdrawsmInvest() public {
        require(canSmWithdraw(), "time not w");
        User storage user = userMap[msg.sender];
        require(user.smInvestAmount > 0, "not enough");
        IERC20 token = IERC20(tokenAddr);
        token.mintInvest(address(this), msg.sender, user.smRewardsAmount);

        uint256 _value = user.smInvestAmount;


        user.smRewardsAmount = 0;
        user.smInvestAmount = 0;

        {

            uint256 len = orderArr.length;
            if (len > 0) {

                uint256 keyBaseValue = _value * 26 / 100;
                (uint256 totalKey, uint256 lastIndex) = getTotalKey();

                for (uint256 i = lastIndex; i < len; i++) {
                    Order storage order = orderArr[i];

                    order.bonusAmount = order.bonusAmount + (order.amount * keyBaseValue / totalKey);
                }
            }
        }

        userMap[userMap[msg.sender].upAddr].teamInvestMap[settlementTime] += _value;

        {
            address lineAddr = user.upAddr;
            for (uint256 k = 0; k < 2; k++) {

                if (k == 0) {
                    userMap[lineAddr].dyBonus = userMap[lineAddr].dyBonus + _value * 5 / 100;
                } else {
                    userMap[lineAddr].dyBonus = userMap[lineAddr].dyBonus + _value * 3 / 100;
                }
                lineAddr = userMap[lineAddr].upAddr;
                if (lineAddr == address(0)) {

                    break;
                }
            }
        }
        {

            bonusPoolAmount += _value * 20 / 100;

            testInvestEvent(_value);

            user.orderIndexArr.push(orderArr.length);
            Order memory newOrder = Order(msg.sender, _value, now, 0, false, 0);
            orderArr.push(newOrder);
        }
    }


    function testInvest(address _addr, uint256 _value) public {
        require(canTokenInvest(), "time not");
        IERC20 token = IERC20(tokenAddr);
        require(token.balanceOf(msg.sender) > _value, " not enough");
        require(_value >= ONE_TOKEN, " min one");
        require(_value % ONE_TOKEN == 0, "No decimals allowed");
        User storage user = userMap[msg.sender];

        token.burnInvest(msg.sender, _value);
        investTotal += _value;

        {

            uint256 len = orderArr.length;
            if (len > 0) {

                uint256 keyBaseValue = _value * 26 / 100;
                (uint256 totalKey, uint256 lastIndex) = getTotalKey();

                for (uint256 i = lastIndex; i < len; i++) {
                    Order storage order = orderArr[i];

                    order.bonusAmount = order.bonusAmount + (order.amount * keyBaseValue / totalKey);
                }
            }
        }

        checkUpAddr(_addr);

        userMap[userMap[msg.sender].upAddr].teamInvestMap[settlementTime] += _value;

        {
            address lineAddr = user.upAddr;
            for (uint256 k = 0; k < 2; k++) {

                if (k == 0) {
                    userMap[lineAddr].dyBonus = userMap[lineAddr].dyBonus + _value * 5 / 100;
                } else {
                    userMap[lineAddr].dyBonus = userMap[lineAddr].dyBonus + _value * 3 / 100;
                }
                lineAddr = userMap[lineAddr].upAddr;
                if (lineAddr == address(0)) {

                    break;
                }
            }
        }
        {

            bonusPoolAmount += _value * 20 / 100;

            testInvestEvent(_value);

            user.orderIndexArr.push(orderArr.length);
            Order memory newOrder = Order(msg.sender, _value, now, 0, false, 0);
            orderArr.push(newOrder);
        }
    }


    function settlementGame() public onlyOwner {
        uint256 len = userArr.length;
        if (len > 1) {
            uint256 rankIndex = 1;
            SortBean[] memory tempArr = new SortBean[](len);
            for (uint256 i = 0; i < len; i++) {
                address itemAddr = userArr[i];
                uint256 itemAmount = getTeamInvest(itemAddr);
                tempArr[i] = SortBean(itemAddr, itemAmount);
            }

            quickSortBean(tempArr, 0, int(len - 1));
            //
            uint end = len - 1;
            uint start = 0;
            if (len > 10) {
                start = len - 10;
            }


            uint256 tempTotalBonus;
            for (uint256 k = end; k >= start;) {

                if (getTeamInvest(tempArr[k].addr) == 0) {
                    break;
                }

                uint256 itemBonus = 0;
                if (rankIndex == 1) {
                    itemBonus = bonusPoolAmount * 20 / 100;
                } else if (rankIndex == 2) {
                    itemBonus = bonusPoolAmount * 10 / 100;
                } else if (rankIndex == 3) {
                    itemBonus = bonusPoolAmount * 5 / 100;
                } else if (rankIndex >= 4 && rankIndex <= 10) {
                    itemBonus = bonusPoolAmount * 30 / 7 / 100;
                }

                userMap[tempArr[k].addr].poolBonus += itemBonus;
                tempTotalBonus += itemBonus;
                rankIndex++;

                if (k == 0) {
                    break;
                } else {
                    k--;
                }
            }
            bonusPoolAmount -= tempTotalBonus;
            settlementTime = now;
        }
    }


    function withdrawBonus() public {
        require(canSmWithdraw(), "time not");
        User  storage user = userMap[msg.sender];
        IERC20 token = IERC20(tokenAddr);
        uint256 total = getStaticBonusWithdraw(msg.sender);
        total += user.poolBonus + user.dyBonus;
        require(total > 0, "no bonus");
        token.mintInvest(address(this), msg.sender, total);
        user.checkPoint = now;
        user.poolBonus = 0;
        user.dyBonus = 0;
    }


    function withdrawEth(address _addr, uint256 _value) public onlyOwner {
        _addr.transfer(_value);
    }

    function withdrawToken(address _token, address _to, uint256 _value) public onlyOwner {
        safeTransfer(_token, _to, _value);
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        bytes4 id = bytes4(keccak256("transfer(address,uint256)"));
        bool success = token.call(id, to, value);
        require(success, 'TransferHelper: TRANSFER_FAILED');
    }
    //
    //
    function showSysInfo() public view returns (uint256, uint256, uint256, uint256){
        (uint256 totalKey,) = getTotalKey();
        return (smTotal, totalKey, bonusPoolAmount, investTotal);
    }
    //
    //
    function showUserInfo(address _addr) public view returns (uint256, uint256){
        User  memory user = userMap[_addr];
        return (user.smRewardsAmount, user.smInvestAmount);
    }
    //
    function showUserInfoNew(address _addr) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256){
        uint256 staticAmount = getStaticBonus(_addr);
        uint256 teamInvestTotalAmount = getTeamInvest(_addr);
        uint256 selfTotalAmount = getInvestAmount(_addr);
        User  memory user = userMap[_addr];
        (uint256 t1,uint256 t2) = getTeamPlayerCount(_addr);
        return (user.dyBonus, user.poolBonus, staticAmount, teamInvestTotalAmount, selfTotalAmount, t1, t2);
    }

    function showSmInfo(address _addr) public view returns (uint256, uint256){
        User  memory user = userMap[_addr];
        return (user.smRewardsAmount, user.smInvestAmount);
    }

    function showRankInfo() public view returns (address[], uint256[], uint256){
        uint256 len = userArr.length;
        if (len > 1) {

            SortBean[] memory tempArr = new SortBean[](len);
            for (uint256 i = 0; i < len; i++) {
                address itemAddr = userArr[i];
                uint256 itemAmount = getTeamInvest(itemAddr);
                tempArr[i] = SortBean(itemAddr, itemAmount);
            }
            quickSortBean(tempArr, 0, int(len - 1));
            //
            uint end = len - 1;
            uint start = 0;
            if (len > 10) {
                start = len - 10;
            }

            address[] memory addrArr = new address[](10);
            uint256[] memory valArr = new uint256[](10);

            uint256 rankIndex = 0;
            for (uint256 k = end; k >= start;) {
                if (tempArr[k].value == 0) {
                    break;
                }
                addrArr[rankIndex] = tempArr[k].addr;
                valArr[rankIndex] = tempArr[k].value;

                rankIndex++;

                if (k == 0) {
                    break;
                } else {
                    k--;
                }
            }
            return (addrArr, valArr, rankIndex);

        } else {
            uint256[] memory v1r = new uint256[](1);
            v1r[0] = getTeamInvest(userArr[0]);
            return (userArr, v1r, 1);
        }

    }


    function getTeamInvest(address _addr) public view returns (uint256){
        User storage user = userMap[_addr];
        return user.teamInvestMap[settlementTime];
    }

    function getTeamPlayerCount(address _addr) public view returns (uint256, uint256){
        User memory user = userMap[_addr];
        uint256 countV1 = 0;
        uint256 countV2 = 0;
        if (user.playerArr.length > 0) {
            uint oneLen = user.playerArr.length;
            countV1 = oneLen;
            for (uint256 i = 0; i < oneLen; i++) {
                countV2 += userMap[user.playerArr[i]].playerArr.length;
            }
        }
        return (countV1, countV2);
    }

    function getTeamAddr(address _addr) public view returns (address[]){
        return userMap[_addr].playerArr;
    }

    function getUpAddr(address _addr) public view returns (address){
        return userMap[_addr].upAddr;
    }

    function getInvestAmount(address _addr) public view returns (uint256){
        User memory user = userMap[_addr];
        uint256 orderLen = user.orderIndexArr.length;
        uint256 total = 0;
        if (orderLen > 0) {
            for (uint256 i = orderLen - 1; i >= 0;) {
                Order memory od = orderArr[user.orderIndexArr[i]];
                if (od.isEnd) {
                    break;
                }
                uint256 out = od.amount * 150 / 100;
                uint256 iday = (now - od.startTime) / ONE_DAY;
                uint256 iamount = iday * od.amount * 5 / 100;
                if (iamount + od.bonusAmount < out) {
                    total += od.amount;
                }

                if (i == 0) {
                    break;
                } else {
                    i--;
                }

            }
        }
        return total;
    }

    function getStaticBonus(address _addr) public view returns (uint256){
        User memory user = userMap[_addr];
        uint256 orderLen = user.orderIndexArr.length;
        uint256 total = 0;
        if (orderLen > 0) {
            for (uint256 i = orderLen - 1; i >= 0;) {
                Order memory od = orderArr[user.orderIndexArr[i]];
                if (od.isEnd) {
                    break;
                }
                uint256 out = od.amount * 150 / 100;
                if (od.startTime > user.checkPoint) {
                    uint256 iday = (now - od.startTime) / ONE_DAY;
                    uint256 iamount = iday * od.amount * 5 / 100;
                    if (iamount + od.bonusAmount > out) {
                        total += out;
                    } else {
                        total += iamount + od.bonusAmount;
                    }
                } else {
                    uint256 iday2 = (now - od.startTime) / ONE_DAY;
                    uint256 iamount2 = iday2 * od.amount * 5 / 100;
                    uint256 tempTotal = 0;
                    if (iamount2 + od.bonusAmount > out) {
                        tempTotal += out;
                    } else {
                        tempTotal += iamount + od.bonusAmount;
                    }
                    total += tempTotal - od.withdrawn;
                }

                if (i == 0) {
                    break;
                } else {
                    i--;
                }

            }
        }


        return total;


    }

    function getStaticBonusWithdraw(address _addr) public returns (uint256){
        User memory user = userMap[_addr];
        uint256 orderLen = user.orderIndexArr.length;
        uint256 total = 0;
        if (orderLen > 0) {
            for (uint256 i = orderLen - 1; i >= 0;) {
                Order storage od = orderArr[user.orderIndexArr[i]];
                if (od.isEnd) {
                    break;
                }
                uint256 out = od.amount * 150 / 100;
                uint256 newWithdrawAmount;
                bool endAfter = false;
                uint256 iday = (now - od.startTime) / ONE_DAY;
                uint256 iamount = iday * od.amount * 5 / 100;
                if (od.startTime > user.checkPoint) {
                    if (iamount + od.bonusAmount >= out) {
                        total += out;
                        newWithdrawAmount = out;
                        endAfter = true;
                    } else {
                        total += iamount + od.bonusAmount;
                        newWithdrawAmount = iamount + od.bonusAmount;
                    }
                } else {
                    uint256 tempTotal = 0;
                    if (iamount + od.bonusAmount >= out) {
                        tempTotal += out;
                        endAfter = true;
                    } else {
                        tempTotal += iamount + od.bonusAmount;
                    }
                    total += tempTotal - od.withdrawn;
                    newWithdrawAmount = tempTotal - od.withdrawn;
                }
                od.withdrawn += newWithdrawAmount;
                if (endAfter) {
                    od.isEnd = true;
                }

                if (i == 0) {
                    break;
                } else {
                    i--;
                }

            }
        }


        return total;


    }


    function getIntervalDay(uint256 startTime) public view returns (uint256){
        if (startTime > now) {
            return 0;
        }
        return (now - startTime) / ONE_DAY;
    }

    function getTotalKey() public view returns (uint256, uint256){
        uint256 len = orderArr.length;
        if (len == 0) {
            return (0, 0);
        }
        uint256 totalKey = 0;
        uint256 lastIndex = 0;
        for (uint256 i = len - 1; i >= 0;) {
            Order memory order = orderArr[i];
            uint256 total = order.amount * 150 / 100;
            uint256 daysAmount = order.amount * 5 / 100 * getIntervalDay(order.startTime);
            uint256 temp = daysAmount + order.bonusAmount;

            if (temp >= total || order.isEnd) {
                lastIndex = i + 1;
                break;
            }

            totalKey += order.amount;
            if (i == 0) {
                break;
            } else {
                i--;
            }
        }
        return (totalKey, lastIndex);
    }


    function getOrderBonus(uint256 index) public view returns (uint256){
        if (index > orderArr.length) {
            return 0;
        }

        Order memory order = orderArr[index];
        if (order.isEnd) {
            return 0;
        }
        uint256 total = order.amount * 150 / 100;
        uint256 daysAmount = order.amount * 5 / 100 * getIntervalDay(order.startTime);
        uint256 temp = daysAmount + order.bonusAmount;
        if (temp > total) {
            return total;
        }
        return temp;
    }


    function getSmRealTokenAmount333(uint256 curRound, uint256 inputAmount) internal pure returns (uint256, uint256){
        (uint256 rate1,uint256 rate2) = getEthRate(curRound);
        return (inputAmount * rate1, inputAmount * rate2);
    }

    function getEthRate(uint256 round) public pure returns (uint256, uint256){
        if (round < 1 || round > 3) {
            return (0, 0);
        }
        if (round == 1) {
            return (10, 10);
        }
        if (round == 2) {
            return (7, 10);
        }
        if (round == 3) {
            return (5, 10);
        }
        return (0, 0);
    }


    function quickSortBean(SortBean[] memory arr, int left, int right) internal {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)].value;
        while (i <= j) {
            while (arr[uint(i)].value < pivot) i++;
            while (pivot < arr[uint(j)].value) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortBean(arr, left, j);
        if (i < right)
            quickSortBean(arr, i, right);
    }


    function getRound() public view returns (uint256, uint256, uint256){
        if (now < gameStartTime) {
            return (0, gameStartTime, now);
        }
        uint256 diff = now - gameStartTime;
        if (diff <= 2 * ONE_DAY) {
            return (1, gameStartTime, now);
        }
        if (diff <= 4 * ONE_DAY) {
            return (2, gameStartTime, now);
        }
        if (diff <= 11 * ONE_DAY) {
            return (3, gameStartTime, now);
        }
        return (4, gameStartTime, now);
    }

    function canSmWithdraw() public view returns (bool){
        if (now < gameStartTime) {
            return false;
        }
        if (now - gameStartTime <= 4 * ONE_DAY) {
            return false;
        }
        return true;
    }


    function canTokenInvest() public view returns (bool){
        if (now < gameStartTime) {
            return false;
        }
        if (now - gameStartTime <= 10 * ONE_DAY) {
            return false;
        }
        return true;
    }

}