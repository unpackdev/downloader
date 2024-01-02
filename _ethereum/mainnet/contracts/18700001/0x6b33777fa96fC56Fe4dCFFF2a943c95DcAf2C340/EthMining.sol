// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Context {
    constructor () { }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address payable newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

contract EthMining is Ownable {
    using SafeMath for uint256;

    uint256 public constant WITHDRAW_MAX_PER_DAY_AMOUNT = 5e18; 
    uint256[] public REFERRAL_PERCENTS = [300, 250, 200, 150, 100, 70, 50]; 
    uint256 public PROJECT_FEE = 50;
    uint256 public DEV_FEE = 30;
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;
    uint256 public constant REFERRAL_DELAY = 1 days;

    uint256 public totalStaked;
    uint256 public totalParticipants = 0;

    struct Plan {
        uint256 time;
        uint256 percent;
        uint256 minAmount;
    }

    Plan[] internal plans;

    struct Refinfo {
        uint8 count;
        uint256 totalAmount;
    }

    mapping(address => Refinfo) public refInfos;

    struct Deposit {
        uint8 plan;
        uint256 amount;
        uint256 start;
        bool withdrawn;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256 bonus;
        uint256 totalBonus;
        uint256 withdrawn;
        uint256 firstwithdrawntime;
        uint256 referralwithdrawntime;
        uint256 daywithdrawnamount;
    }

    mapping(address => User) internal users;

    bool public started;
    address public feeWallet;
    address private devWallet;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 amount);
    event Compound(address indexed user, uint8 plan, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event WithdrawnBonus(address indexed user, uint256 amount);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event FeePayed(address indexed user, uint256 totalAmount);
    event FeeWalletUpdated(
        address indexed oldFeeWallet,
        address indexed newFeeWallet
    );
    event DevWalletUpdated(
        address indexed oldDevWallet,
        address indexed newDevWallet
    );

    constructor(
        address wallet,
        address dev
    ) {
        require(!isContract(wallet));
        feeWallet = wallet;
        require(!isContract(dev));
        devWallet = dev;

        plans.push(Plan(7, 30, 0.1 ether));
        plans.push(Plan(15, 50, 1 ether));
        plans.push(Plan(30, 80, 2 ether));
        plans.push(Plan(90, 140, 5 ether));
    }

    receive() external payable {}

    function stake(
        address referrer,
        uint8 plan
    ) external payable {
        if (!started) {
            if (msg.sender == feeWallet) {
                started = true;
            } else revert("Not started yet");
        }

        uint256 amount = msg.value;
        require(amount >= plans[plan].minAmount);
        require(plan < 4, "Invalid plan");
        require(referrer != msg.sender, "Invalid referrer");

        uint256 fee = amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        payable(feeWallet).transfer(fee);
        uint256 devfee = amount.mul(DEV_FEE).div(PERCENTS_DIVIDER);
        payable(devWallet).transfer(devfee);

        emit FeePayed(msg.sender, fee.add(devfee));

        User storage user = users[msg.sender];

        if (referrer != address(0)) {
            user.referrer = referrer;
            if (refInfos[referrer].totalAmount == 0) {
                refInfos[referrer].count = refInfos[referrer].count + 1;
            }
            refInfos[referrer].totalAmount = refInfos[referrer].totalAmount.add(amount);
            uint256 refamount = 0;
            if (refInfos[referrer].totalAmount >= 50 * (10 ** 18)) {
                refamount = amount.mul(REFERRAL_PERCENTS[0]).div(PERCENTS_DIVIDER);
            } else if (refInfos[referrer].totalAmount >= 25 * (10 ** 18)) {
                refamount = amount.mul(REFERRAL_PERCENTS[1]).div(PERCENTS_DIVIDER);
            } else if (refInfos[referrer].totalAmount >= 10 * (10 ** 18)) {
                refamount = amount.mul(REFERRAL_PERCENTS[2]).div(PERCENTS_DIVIDER);
            } else if (refInfos[referrer].totalAmount >= 5 * (10 ** 18)) {
                refamount = amount.mul(REFERRAL_PERCENTS[3]).div(PERCENTS_DIVIDER);
            } else if (refInfos[referrer].totalAmount >= 2 * (10 ** 18)) {
                refamount = amount.mul(REFERRAL_PERCENTS[4]).div(PERCENTS_DIVIDER);
            } else if (refInfos[referrer].totalAmount >= 1 * (10 ** 18)) {
                refamount = amount.mul(REFERRAL_PERCENTS[5]).div(PERCENTS_DIVIDER);
            } else {
                refamount = amount.mul(REFERRAL_PERCENTS[6]).div(PERCENTS_DIVIDER);
            }
            users[referrer].bonus = users[referrer].bonus.add(refamount);
            users[referrer].totalBonus = users[referrer].totalBonus.add(refamount);
            
            emit RefBonus(referrer, msg.sender, 0, refamount);
        }

        if (user.deposits.length == 0) {
            totalParticipants = totalParticipants.add(1);
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(plan, amount, block.timestamp, false));

        totalStaked = totalStaked.add(amount);

        emit NewDeposit(msg.sender, plan, amount);
    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint256 totalAmount = getUserDividends(msg.sender);
        uint256 referralBonus = getUserReferralBonus(msg.sender);

        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount = totalAmount.add(referralBonus);
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            user.bonus = totalAmount.sub(contractBalance);
            totalAmount = contractBalance;
        }

        if (block.timestamp - user.firstwithdrawntime <= TIME_STEP) {
            require(
                user.daywithdrawnamount < WITHDRAW_MAX_PER_DAY_AMOUNT,
                "Exceed max withdrawn amount today"
            );

            if (
                user.daywithdrawnamount.add(totalAmount) >
                WITHDRAW_MAX_PER_DAY_AMOUNT
            ) {
                uint256 additionalBonus = user
                    .daywithdrawnamount
                    .add(totalAmount)
                    .sub(WITHDRAW_MAX_PER_DAY_AMOUNT);
                user.bonus = user.bonus.add(additionalBonus);
                totalAmount = WITHDRAW_MAX_PER_DAY_AMOUNT.sub(
                    user.daywithdrawnamount
                );
            }
            user.daywithdrawnamount = user.daywithdrawnamount.add(totalAmount);
        } else {
            if (totalAmount > WITHDRAW_MAX_PER_DAY_AMOUNT) {
                uint256 additionalBonus = totalAmount.sub(
                    WITHDRAW_MAX_PER_DAY_AMOUNT
                );
                user.bonus = user.bonus.add(additionalBonus);
                totalAmount = WITHDRAW_MAX_PER_DAY_AMOUNT;
            }
            user.firstwithdrawntime = block.timestamp;
            user.daywithdrawnamount = totalAmount;
        }

        user.checkpoint = block.timestamp;
        user.withdrawn = user.withdrawn.add(totalAmount);
        for (uint256 i = 0; i < user.deposits.length; i++) {
            uint256 finish = user.deposits[i].start.add(
                plans[user.deposits[i].plan].time.mul(1 days)
            );
            if (user.checkpoint > finish) {
                user.deposits[i].withdrawn = true;
            }
        }
        payable(msg.sender).transfer(totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }

    function withdrawReferralBonus() public {
        User storage user = users[msg.sender];
        require(user.referralwithdrawntime + REFERRAL_DELAY < block.timestamp, "No withdrawal twice a day");
        uint256 referralBonus = getUserReferralBonus(msg.sender);

        uint256 contractBalance = address(this).balance;
        if (contractBalance < referralBonus) {
            user.bonus = referralBonus.sub(contractBalance);
            referralBonus = contractBalance;
        } else {
            user.bonus = 0;
        }

        payable(msg.sender).transfer(referralBonus);
        user.referralwithdrawntime = block.timestamp;
        emit WithdrawnBonus(msg.sender, referralBonus);
    }

    function getRefInfo(address _addr) public view returns (Refinfo memory) {
        return refInfos[_addr];
    }

    function compound(uint8 plan) public payable {
        User storage user = users[msg.sender];
        uint256 amount = msg.value;

        uint256 totalAmount = getUserDividends(msg.sender);
        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
        }

        require(totalAmount > 0, "User has no Dividends");
        require(amount < totalAmount, "Compound Amount is Over");
        require(amount >= plans[plan].minAmount);

        uint256 contractBalance = address(this).balance;
        if (contractBalance < amount) {
            user.bonus = amount.sub(contractBalance);
            amount = contractBalance;
        } else if (referralBonus > 0) {
            if (referralBonus > amount) {
                user.bonus = user.bonus.sub(amount);
            } else {
                user.bonus = totalAmount.sub(amount);
                user.checkpoint = block.timestamp;
            }
        }

        uint256 fee = amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        payable(feeWallet).transfer(fee);
        uint256 devfee = amount.mul(DEV_FEE).div(PERCENTS_DIVIDER);
        payable(devWallet).transfer(devfee);

        emit FeePayed(msg.sender, fee.add(devfee));

        user.deposits.push(Deposit(plan, amount, block.timestamp, false));
        totalStaked = totalStaked.add(amount);
        user.checkpoint = block.timestamp;

        emit Compound(msg.sender, plan, amount);
    }

    function canHarvest(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (block.timestamp - user.firstwithdrawntime <= TIME_STEP) {
            return user.daywithdrawnamount < WITHDRAW_MAX_PER_DAY_AMOUNT;
        } else {
            return true;
        }
    }

    function canRestake(address userAddress, uint8 plan)
        public
        view
        returns (bool)
    {
        uint256 totalAmount = getUserDividends(userAddress);
        uint256 referralBonus = getUserReferralBonus(userAddress);
        if (referralBonus > 0) totalAmount = totalAmount.add(referralBonus);

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) totalAmount = contractBalance;

        return (totalAmount >= plans[plan].minAmount);
    }

    function updateFeeWallet(address wallet) external {
        require(msg.sender == feeWallet, "Limited Permission");
        emit FeeWalletUpdated(feeWallet, wallet);
        feeWallet = wallet;
    }

    function updateDevWallet(address dev) external {
        require(msg.sender == devWallet, "Limited Permission");
        emit DevWalletUpdated(devWallet, dev);
        devWallet = dev;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlanInfo(uint8 plan)
        public
        view
        returns (
            uint256 time,
            uint256 percent,
            uint256 minAmount
        )
    {
        time = plans[plan].time;
        percent = plans[plan].percent;
        minAmount = plans[plan].minAmount;
    }

    function getUserDividends(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            uint256 finish = user.deposits[i].start.add(
                plans[user.deposits[i].plan].time.mul(1 days)
            );
            if (user.checkpoint < finish) {
                uint256 share = user
                    .deposits[i]
                    .amount
                    .mul(plans[user.deposits[i].plan].percent)
                    .div(PERCENTS_DIVIDER);
                uint256 from = user.deposits[i].start > user.checkpoint
                    ? user.deposits[i].start
                    : user.checkpoint;
                uint256 to = finish < block.timestamp
                    ? finish
                    : block.timestamp;
                if (from < to) {
                    totalAmount = totalAmount.add(
                        share.mul(to.sub(from)).div(TIME_STEP)
                    );
                }
            }
            if (block.timestamp > finish && !user.deposits[i].withdrawn) {
                totalAmount = totalAmount.add(user.deposits[i].amount);
            }
        }
        return totalAmount;
    }

    function getUserActiveStaking(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            uint256 finish = user.deposits[i].start.add(
                plans[user.deposits[i].plan].time.mul(1 days)
            );
            if (block.timestamp < finish) {
                totalAmount = totalAmount.add(user.deposits[i].amount);
            } 
        }
        return totalAmount;
    }

    function getUserTotalWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].withdrawn;
    }

    function getUserCheckpoint(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return users[userAddress].referrer;
    }

    function getUserTotalReferrals(address userAddress)
        public
        view
        returns (uint256)
    {
        return
            refInfos[userAddress].count;
    }

    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus;
    }

    function getUserReferralWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus.sub(users[userAddress].bonus);
    }

    function getUserAvailable(address userAddress)
        public
        view
        returns (uint256)
    {
        return
            getUserReferralBonus(userAddress).add(
                getUserDividends(userAddress)
            );
    }

    function getUserAmountOfDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (
            uint8 plan,
            uint256 percent,
            uint256 amount,
            uint256 start,
            uint256 finish
        )
    {
        User storage user = users[userAddress];

        plan = user.deposits[index].plan;
        percent = plans[plan].percent;
        amount = user.deposits[index].amount;
        start = user.deposits[index].start;
        finish = user.deposits[index].start.add(
            plans[user.deposits[index].plan].time.mul(1 days)
        );
    }

    function getUserPlanInfo(address userAddress)
        public
        view
        returns (uint256[] memory planAmount)
    {
        User storage user = users[userAddress];
        uint256 index = getUserAmountOfDeposits(userAddress);
        planAmount = new uint256[](4);

        for (uint256 i = 0; i < index; i++) {
            uint256 userPlan = user.deposits[i].plan;
            uint256 amount = user.deposits[i].amount;
            planAmount[userPlan] = planAmount[userPlan].add(amount);
        }

        return planAmount;
    }

    function getSiteInfo()
        public
        view
        returns (uint256 _totalStaked)
    {
        return (totalStaked);
    }

    function getUserInfo(address userAddress)
        public
        view
        returns (
            uint256 totalDeposit,
            uint256 totalWithdrawn,
            uint256 totalReferrals
        )
    {
        return (
            getUserTotalDeposits(userAddress),
            getUserTotalWithdrawn(userAddress),
            getUserTotalReferrals(userAddress)
        );
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function setProjectFee(uint256 _PROJECT_FEE) external onlyOwner {
        PROJECT_FEE = _PROJECT_FEE;
    }
}