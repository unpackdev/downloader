pragma solidity >=0.5.16;
pragma experimental ABIEncoderV2;

import "./EIP20Interface.sol";
import "./SafeMath.sol";

contract EsgSHIPV3{
    using SafeMath for uint256;
    /// @notice ESG token
    EIP20Interface public esg;

    /// @notice Emitted when referral set invitee
    event SetInvitee(address inviteeAddress);

    /// @notice Emitted when owner set invitee
    event SetInviteeByOwner(address referrerAddress, address inviteeAddress);

    /// @notice Emitted when ESG is invest  
    event EsgInvest(address account, uint amount, uint price);

    /// @notice Emitted when ESG is invest by owner 
    event EsgInvestByOwner(address account, uint amount, uint price);

    /// @notice Emitted when ESG is claimed 
    event EsgClaimed(address account, uint amount, uint price);

    /// @notice Emitted when change Lock info
    event EsgChangeLockInfo(address _user, uint256 _rate, uint256 i);

    /// @notice Emitted when change Investment info
    event EsgChangeInvestmentInfo(address _user, uint256 _userTotalValue, uint256 _withdraw, uint256 _lastCollectionTime);

    /// @notice Emitted when change Referrer info
    event EsgChangeReferrerInfo(address _user, uint256 _totalInvestment, uint256 _referrerRewardLimit, uint256 _totalReferrerRaward, uint256 _teamRewardTime, uint256 _teamRewardRate, uint256 _noExtract);

    struct Lock {
        uint256 amount;
        uint256 esgPrice;
        uint256 value;
        uint256 start;
        uint256 end;
        uint256 investDays;
        uint256 releaseRate;
    }
    mapping(address => Lock[]) public locks;

    struct Investment {
        uint256 userTotalValue;
        uint256 withdraw; 
        uint256 lastCollectionTime;
    }
    mapping(address => Investment) public investments;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    struct Referrer {
        address[] referrals;
        uint256 totalInvestment;
        uint256 referrerRewardLimit;
        uint256 totalReferrerRaward;
        uint256 teamRewardTime;
        uint256 teamRewardRate;
        uint256 noExtract;
    }
    mapping(address => Referrer) public referrers;//1:n

    struct User {
        address referrer_addr;
    }
    mapping (address => User) public referrerlist;//1:1

    uint256 public invest_days1 = 500;
    uint256 public invest_days2 = 450;
    uint256 public invest_days3 = 400;
    uint256 public invest_days4 = 350;
    uint256 public invest_days5 = 300;
    uint256 public referralThreshold = 1000 * 1e24;
    uint256 public total_deposited;
    uint256 public total_user;
    uint256 public total_amount;
    uint256 public total_extracted;
    uint256 public total_claim_amount;
    uint256 public lockRates = 100;
    uint256 public staticRewardRate = 10;
    uint256 public dynamicRewardRate = 10;
    uint256 public teamRewardThreshold = 30000 * 1e24;
    uint256 public teamRewardThresholdRate = 30 * 1e24;
    uint256 public teamRewardThresholdStep = 10000 * 1e24;
    uint256 public teamRewardThresholdStepRate = 10 * 1e24;
    uint256 public price;
    bool public investEnabled;
    bool public claimEnabled;
    address public owner;

    constructor(address esgAddress) public {
        owner = msg.sender;
        investEnabled = true;
        claimEnabled = true;
        esg = EIP20Interface(esgAddress);
    }

    function setPrice(uint256 _price) onlyOwner public {
        require(_price > 0, "Price must be positive");
        price = _price;
    }

    function setInvestEnabled(bool _investEnabled) onlyOwner public {
        investEnabled = _investEnabled;
    }

    function setClaimEnabled(bool _claimEnabled) onlyOwner public {
        claimEnabled = _claimEnabled;
    }

    function setInvestDays(uint256 days1, uint256 days2, uint256 days3, uint256 days4, uint256 days5) onlyOwner public {
        require(days1 > 0, "days1 should be greater than 0");
        require(days2 > 0, "days2 should be greater than 0");
        require(days3 > 0, "days3 should be greater than 0");
        require(days4 > 0, "days4 should be greater than 0");
        require(days5 > 0, "days5 should be greater than 0");
        invest_days1 = days1;
        invest_days2 = days2;
        invest_days3 = days3;
        invest_days4 = days4;
        invest_days5 = days5;
    }

    function setLockRates(uint256 _lockRates) onlyOwner public {
        lockRates = _lockRates;
    }

    function setReferralThreshold(uint256 _referralThreshold) onlyOwner public {
        referralThreshold = _referralThreshold;
    }

    function setStaticRewardRate(uint256 _staticRewardRate) onlyOwner public {
        staticRewardRate = _staticRewardRate;
    }

    function setDynamicRewardRate(uint256 _dynamicRewardRate) onlyOwner public {
        dynamicRewardRate = _dynamicRewardRate;
    }

    function setTeamRewardThreshold(uint256 _teamRewardThreshold) onlyOwner public {
        teamRewardThreshold = _teamRewardThreshold;
    }

    function setTeamRewardThresholdRate(uint256 _teamRewardThresholdRate) onlyOwner public {
        teamRewardThresholdRate = _teamRewardThresholdRate;
    }

    function setTeamRewardThresholdStep(uint256 _teamRewardThresholdStep) onlyOwner public {
        teamRewardThresholdStep = _teamRewardThresholdStep;
    }

    function setTeamRewardThresholdStepRate(uint256 _teamRewardThresholdStepRate) onlyOwner public {
        teamRewardThresholdStepRate = _teamRewardThresholdStepRate;
    }

    function setInvitee(address inviteeAddress) public returns (bool) {
        require(inviteeAddress != address(0), "inviteeAddress cannot be 0x0.");

        User storage user = referrerlist[inviteeAddress];
        require(user.referrer_addr == address(0), "This account had been invited!");
        
        Investment storage investment = investments[msg.sender];
        require(investment.userTotalValue.mul(lockRates).div(100).add(investment.userTotalValue).sub(investment.withdraw) >= referralThreshold, "Referrer has no referral qualification.");

        Lock[] storage inviteeLocks = locks[inviteeAddress];
        require(inviteeLocks.length == 0, "This account had staked!");
        
        Referrer storage referrer = referrers[msg.sender];
        referrer.referrals.push(inviteeAddress);
        if(referrer.referrerRewardLimit == 0){
            referrer.referrerRewardLimit = investment.userTotalValue.mul(lockRates).div(100).add(investment.userTotalValue);
        }

        User storage _user = referrerlist[inviteeAddress];
        _user.referrer_addr = msg.sender;

        emit SetInvitee(inviteeAddress);
        return true;   
    }

    function setInviteeByOwner(address referrerAddress, address inviteeAddress) public onlyOwner returns (bool) {
        require(referrerAddress != address(0), "referrerAddress cannot be 0x0.");
        require(inviteeAddress != address(0), "inviteeAddress cannot be 0x0.");

        User storage user = referrerlist[inviteeAddress];
        require(user.referrer_addr == address(0), "This account had been invited!");
        
        Investment storage investment = investments[referrerAddress];
        require(investment.userTotalValue.mul(lockRates).div(100).add(investment.userTotalValue).sub(investment.withdraw) >= referralThreshold, "Referrer has no referral qualification.");

        Lock[] storage inviteeLocks = locks[inviteeAddress];
        require(inviteeLocks.length == 0, "This account had staked!");
        
        Referrer storage referrer = referrers[referrerAddress];
        referrer.referrals.push(inviteeAddress);
        if(referrer.referrerRewardLimit == 0){
            referrer.referrerRewardLimit = investment.userTotalValue.mul(lockRates).div(100).add(investment.userTotalValue);
        }

        User storage _user = referrerlist[inviteeAddress];
        _user.referrer_addr = referrerAddress;

        emit SetInviteeByOwner(referrerAddress, inviteeAddress);
        return true;   
    }

    function getInviteelist(address referrerAddress) public view returns (address[] memory) {
        require(referrerAddress != address(0), "referrerAddress cannot be 0x0.");
        Referrer storage referrer = referrers[referrerAddress];
        return referrer.referrals;
    }

    function getReferrer(address inviteeAddress) public view returns (address) {
        require(inviteeAddress != address(0), "inviteeAddress cannot be 0x0.");
        User storage user = referrerlist[inviteeAddress];
        return user.referrer_addr;
    }

    function invest(uint256 _amount) public returns (bool) {
        require(investEnabled == true, "No invest allowed!");
        require(_amount > 0, "Invalid amount.");

        esg.transferFrom(msg.sender, address(this), _amount);

        uint256 invest_days = 0;
        uint256 deposit = _amount.mul(price);
        if(deposit < 500 * 1e24){
            invest_days = invest_days1;
        }else if(deposit >= 500 * 1e24 && deposit < 2000 * 1e24){
            invest_days = invest_days2;
        }else if(deposit >= 2000 * 1e24 && deposit < 5000 * 1e24){
            invest_days = invest_days3;
        }else if(deposit >= 5000 * 1e24 && deposit < 10000 * 1e24){
            invest_days = invest_days4;
        }else if(deposit >= 10000 * 1e24){
            invest_days = invest_days5;
        }

        uint256 nowTime = block.timestamp;

        locks[msg.sender].push(
            Lock(
                _amount,
                price,
                deposit,
                nowTime,
                nowTime + (invest_days * 86400),
                invest_days,
                (deposit.mul(lockRates).div(100).add(deposit)).div(invest_days).div(86400)
            )
        );

        Investment storage investment = investments[msg.sender];
        if(investment.userTotalValue == 0){
            investment.lastCollectionTime = nowTime;
            total_user = total_user + 1;
        }
        investment.userTotalValue += deposit;

        total_deposited = total_deposited + deposit;
        total_amount = total_amount + _amount;

        Referrer storage userReferrer = referrers[msg.sender];
        if(userReferrer.referrals.length > 0){
            userReferrer.referrerRewardLimit = investment.userTotalValue.mul(lockRates).div(100).add(investment.userTotalValue);
        }
            
        User storage user = referrerlist[msg.sender];

        if(user.referrer_addr != address(0)){
            referrers[user.referrer_addr].totalInvestment += deposit;
            uint256 staticReward = deposit.mul(staticRewardRate).div(100);
            Referrer storage referrer = referrers[user.referrer_addr];
            Lock[] storage userLocks = locks[user.referrer_addr];
            if(referrer.totalReferrerRaward < referrer.referrerRewardLimit){
                if(referrer.totalReferrerRaward + staticReward < referrer.referrerRewardLimit){
                    referrer.noExtract += staticReward;
                    if(referrer.noExtract >= referrer.referrerRewardLimit){
                        for (uint256 i = 0; i < userLocks.length; i++) {
                            Lock storage lock = userLocks[i];
                            lock.releaseRate = 0;
                        }
                    }
                }else{
                    referrer.noExtract = referrer.referrerRewardLimit - referrer.totalReferrerRaward;
                    for (uint256 i = 0; i < userLocks.length; i++) {
                        Lock storage lock = userLocks[i];
                        lock.releaseRate = 0;
                    }
                }
            }
            
            if(referrer.totalInvestment >= teamRewardThreshold){
                uint256 statistics = 0;
                if(referrer.teamRewardTime == 0){
                    referrer.teamRewardTime = block.timestamp;
                    statistics = (referrer.totalInvestment.sub(teamRewardThreshold)).div(teamRewardThresholdStep);
                    referrer.teamRewardRate = teamRewardThresholdStepRate.mul(statistics).div(86400);
                    referrer.teamRewardRate += teamRewardThresholdRate.div(86400);
                }else{
                    uint256 team_reward = (block.timestamp.sub(referrer.teamRewardTime)).mul(referrer.teamRewardRate);
                    if(referrer.totalReferrerRaward < referrer.referrerRewardLimit){
                        if(referrer.totalReferrerRaward + team_reward < referrer.referrerRewardLimit){
                            referrer.noExtract += team_reward;
                            if(referrer.noExtract >= referrer.referrerRewardLimit){
                                for (uint256 i = 0; i < userLocks.length; i++) {
                                    Lock storage lock = userLocks[i];
                                    lock.releaseRate = 0;
                                }
                            }
                        }else{
                            referrer.noExtract = referrer.referrerRewardLimit - referrer.totalReferrerRaward;
                            for (uint256 i = 0; i < userLocks.length; i++) {
                                Lock storage lock = userLocks[i];
                                lock.releaseRate = 0;
                            }
                        }
                        referrer.teamRewardTime = block.timestamp;
                        statistics = (referrer.totalInvestment.sub(teamRewardThreshold)).div(teamRewardThresholdStep);
                        referrer.teamRewardRate = teamRewardThresholdStepRate.mul(statistics).div(86400);
                        referrer.teamRewardRate += teamRewardThresholdRate.div(86400);
                    }
                }
            }
        }

        emit EsgInvest(msg.sender, _amount, price);
        return true;
    }

    function investByOwner(address investAddress, uint256 _amount) public onlyOwner returns (bool) {
        require(investEnabled == true, "No invest allowed!");
        require(_amount > 0, "Invalid amount.");

        uint256 invest_days = 0;
        uint256 deposit = _amount.mul(price);
        if(deposit < 500 * 1e24){
            invest_days = invest_days1;
        }else if(deposit >= 500 * 1e24 && deposit < 2000 * 1e24){
            invest_days = invest_days2;
        }else if(deposit >= 2000 * 1e24 && deposit < 5000 * 1e24){
            invest_days = invest_days3;
        }else if(deposit >= 5000 * 1e24 && deposit < 10000 * 1e24){
            invest_days = invest_days4;
        }else if(deposit >= 10000 * 1e24){
            invest_days = invest_days5;
        }

        uint256 nowTime = block.timestamp;

        locks[investAddress].push(
            Lock(
                _amount,
                price,
                deposit,
                nowTime,
                nowTime + (invest_days * 86400),
                invest_days,
                (deposit.mul(lockRates).div(100).add(deposit)).div(invest_days).div(86400)
            )
        );

        Investment storage investment = investments[investAddress];
        if(investment.userTotalValue == 0){
            investment.lastCollectionTime = nowTime;
            total_user = total_user + 1;
        }
        investment.userTotalValue += deposit;

        total_deposited = total_deposited + deposit;
        total_amount = total_amount + _amount;

        Referrer storage userReferrer = referrers[msg.sender];
        if(userReferrer.referrals.length > 0){
            userReferrer.referrerRewardLimit = investment.userTotalValue.mul(lockRates).div(100).add(investment.userTotalValue);
        }
            
        User storage user = referrerlist[investAddress];

        if(user.referrer_addr != address(0)){
            referrers[user.referrer_addr].totalInvestment += deposit;
            uint256 staticReward = deposit.mul(staticRewardRate).div(100);
            Referrer storage referrer = referrers[user.referrer_addr];
            Lock[] storage userLocks = locks[user.referrer_addr];
            if(referrer.totalReferrerRaward < referrer.referrerRewardLimit){
                if(referrer.totalReferrerRaward + staticReward < referrer.referrerRewardLimit){
                    referrer.noExtract += staticReward;
                    if(referrer.noExtract >= referrer.referrerRewardLimit){
                        for (uint256 i = 0; i < userLocks.length; i++) {
                            Lock storage lock = userLocks[i];
                            lock.releaseRate = 0;
                        }
                    }
                }else{
                    referrer.noExtract = referrer.referrerRewardLimit - referrer.totalReferrerRaward;
                    for (uint256 i = 0; i < userLocks.length; i++) {
                        Lock storage lock = userLocks[i];
                        lock.releaseRate = 0;
                    }
                }
            }
            
            if(referrer.totalInvestment >= teamRewardThreshold){
                uint256 statistics = 0;
                if(referrer.teamRewardTime == 0){
                    referrer.teamRewardTime = block.timestamp;
                    statistics = (referrer.totalInvestment.sub(teamRewardThreshold)).div(teamRewardThresholdStep);
                    referrer.teamRewardRate = teamRewardThresholdStepRate.mul(statistics).div(86400);
                    referrer.teamRewardRate += teamRewardThresholdRate.div(86400);
                }else{
                    uint256 team_reward = (block.timestamp.sub(referrer.teamRewardTime)).mul(referrer.teamRewardRate);
                    if(referrer.totalReferrerRaward < referrer.referrerRewardLimit){
                        if(referrer.totalReferrerRaward + team_reward < referrer.referrerRewardLimit){
                            referrer.noExtract += team_reward;
                            if(referrer.noExtract >= referrer.referrerRewardLimit){
                                for (uint256 i = 0; i < userLocks.length; i++) {
                                    Lock storage lock = userLocks[i];
                                    lock.releaseRate = 0;
                                }
                            }
                        }else{
                            referrer.noExtract = referrer.referrerRewardLimit - referrer.totalReferrerRaward;
                            for (uint256 i = 0; i < userLocks.length; i++) {
                                Lock storage lock = userLocks[i];
                                lock.releaseRate = 0;
                            }
                        }
                        referrer.teamRewardTime = block.timestamp;
                        statistics = (referrer.totalInvestment.sub(teamRewardThreshold)).div(teamRewardThresholdStep);
                        referrer.teamRewardRate = teamRewardThresholdStepRate.mul(statistics).div(86400);
                        referrer.teamRewardRate += teamRewardThresholdRate.div(86400);
                    }
                }
            }
        }

        emit EsgInvestByOwner(investAddress, _amount, price);
        return true;
    }

    function claim() public returns (bool) {
        require(claimEnabled == true, "No claim allowed!");
        Lock[] storage userLocks = locks[msg.sender];
        require(userLocks.length > 0, "No locked amount.");

        uint256 totalInterest = 0;
        Investment storage investment = investments[msg.sender];
        uint256 userDeposit = investment.userTotalValue.mul(lockRates).div(100).add(investment.userTotalValue);
        uint256 userWithdraw = investment.withdraw;
        require(userDeposit > userWithdraw, "All investments have been fully withdrawn");

        for (uint256 i = 0; i < userLocks.length; i++) {
            Lock storage lock = userLocks[i];
            uint256 interest = (block.timestamp.sub(investment.lastCollectionTime)).mul(lock.releaseRate);
            if (interest > 0) {
                totalInterest += interest;
            }
        }

        Referrer storage referrer_user = referrers[msg.sender];
        if(userDeposit - userWithdraw >= referralThreshold){
            if(referrer_user.totalInvestment > 0){
                if(referrer_user.totalReferrerRaward + referrer_user.noExtract <= referrer_user.referrerRewardLimit){
                    totalInterest += referrer_user.noExtract;
                    referrer_user.totalReferrerRaward += referrer_user.noExtract;
                    if(referrer_user.totalReferrerRaward > referrer_user.referrerRewardLimit){
                        referrer_user.totalReferrerRaward = referrer_user.referrerRewardLimit;
                    }
                    referrer_user.noExtract = 0;
                }else{
                    if(referrer_user.referrerRewardLimit > referrer_user.totalReferrerRaward){
                        totalInterest += referrer_user.referrerRewardLimit - referrer_user.totalReferrerRaward;
                    }
                    referrer_user.totalReferrerRaward = referrer_user.referrerRewardLimit;
                    referrer_user.noExtract = 0;
                }
                
                uint256 team_reward = (block.timestamp.sub(referrer_user.teamRewardTime)).mul(referrer_user.teamRewardRate);
                if(referrer_user.teamRewardTime > 0 && referrer_user.teamRewardRate > 0){
                    if(referrer_user.totalReferrerRaward + team_reward <= referrer_user.referrerRewardLimit){
                        totalInterest += team_reward;
                        referrer_user.totalReferrerRaward += team_reward;
                        if(referrer_user.totalReferrerRaward > referrer_user.referrerRewardLimit){
                            referrer_user.totalReferrerRaward = referrer_user.referrerRewardLimit;
                        }
                        referrer_user.teamRewardTime = block.timestamp;
                    }else{
                        if(referrer_user.referrerRewardLimit > referrer_user.totalReferrerRaward){
                            totalInterest += referrer_user.referrerRewardLimit - referrer_user.totalReferrerRaward;
                        }
                        referrer_user.totalReferrerRaward = referrer_user.referrerRewardLimit;
                        referrer_user.teamRewardTime = block.timestamp;
                    }
                }
            }
        }
        require(totalInterest > 0, "No interest to claim.");
        investment.lastCollectionTime = block.timestamp;

        uint256 transfer_amount = 0;
        uint256 total_withdraw = investment.withdraw + totalInterest;
        if(total_withdraw >= userDeposit){
            transfer_amount = (userDeposit.sub(userWithdraw)).div(price);
            investment.withdraw = userDeposit;   
            esg.transfer(msg.sender, transfer_amount);
            for (uint256 i = 0; i < userLocks.length; i++) {
                Lock storage user_lock = userLocks[i];
                user_lock.releaseRate = 0;
            }
        }else{
            transfer_amount = totalInterest.div(price);
            investment.withdraw += totalInterest;
            esg.transfer(msg.sender, transfer_amount);
        }
        total_claim_amount += transfer_amount;
        total_extracted += transfer_amount.mul(price);
        
        User storage user = referrerlist[msg.sender];
        if (user.referrer_addr != address(0)) {
            Referrer storage referrer = referrers[user.referrer_addr];
            uint256 dynamic_reward = totalInterest.mul(dynamicRewardRate).div(100);
            Lock[] storage referrerLocks = locks[user.referrer_addr];
            if(referrer.totalReferrerRaward < referrer.referrerRewardLimit){
                if(referrer.totalReferrerRaward + dynamic_reward < referrer.referrerRewardLimit){
                    referrer.noExtract += dynamic_reward;
                    if(referrer.noExtract >= referrer.referrerRewardLimit){
                        for (uint256 i = 0; i < userLocks.length; i++) {
                            Lock storage lock = userLocks[i];
                            lock.releaseRate = 0;
                        }
                    }
                }else{
                    referrer.noExtract = referrer.referrerRewardLimit - referrer.totalReferrerRaward;
                    for (uint256 i = 0; i < referrerLocks.length; i++) {
                        Lock storage referrer_lock = referrerLocks[i];
                        referrer_lock.releaseRate = 0;
                    }
                }
            }
        }

        emit EsgClaimed (msg.sender, transfer_amount, price); 
        return true;
    }

    function getClaimAmount(address _user) public view returns (uint256) {
        require(_user != address(0), "_user cannot be 0x0.");
        Lock[] storage userLocks = locks[_user];
        uint256 totalInterest = 0;
        Investment storage investment = investments[_user];
        uint256 userDeposit = investment.userTotalValue.mul(lockRates).div(100).add(investment.userTotalValue);
        uint256 userWithdraw = investment.withdraw;
        if(userWithdraw >= userDeposit){
            return 0;
        }

        for (uint256 i = 0; i < userLocks.length; i++) {
            Lock storage lock = userLocks[i];
            uint256 interest = (block.timestamp.sub(investment.lastCollectionTime)).mul(lock.releaseRate);
            if (interest > 0) {
                totalInterest += interest;
            }
        }

        Referrer storage referrer_user = referrers[_user];
        uint256 total_reward = referrer_user.totalReferrerRaward;
        if(userDeposit.sub(userWithdraw) >= referralThreshold){
            if(referrer_user.totalInvestment > 0){
                if(total_reward + referrer_user.noExtract <= referrer_user.referrerRewardLimit){
                    totalInterest += referrer_user.noExtract;
                    total_reward += referrer_user.noExtract;
                }else{
                    if(referrer_user.referrerRewardLimit > referrer_user.totalReferrerRaward){
                        totalInterest += referrer_user.referrerRewardLimit - referrer_user.totalReferrerRaward;
                        total_reward = referrer_user.referrerRewardLimit;
                    }
                }
                
                uint256 team_reward = (block.timestamp.sub(referrer_user.teamRewardTime)).mul(referrer_user.teamRewardRate);
                if(referrer_user.teamRewardTime > 0 && referrer_user.teamRewardRate > 0){
                    if(total_reward + team_reward <= referrer_user.referrerRewardLimit){
                        totalInterest += team_reward;
                    }else{
                        if(referrer_user.referrerRewardLimit > referrer_user.totalReferrerRaward){
                            totalInterest += referrer_user.referrerRewardLimit - referrer_user.totalReferrerRaward;
                        }
                    }
                }
            }
        }

        uint256 total_withdraw = investment.withdraw + totalInterest;
        uint256 transfer_amount = 0;
        if(total_withdraw >= userDeposit){   
            transfer_amount = userDeposit.sub(userWithdraw);
        }else{
            transfer_amount = totalInterest;
        }
        return transfer_amount;
    }

    function getNoExtract(address _user) public view returns (uint256) {
        require(_user != address(0), "_user cannot be 0x0.");
        uint256 totalInterest = 0;
        Investment storage investment = investments[_user];
        uint256 userDeposit = investment.userTotalValue.mul(lockRates).div(100).add(investment.userTotalValue);
        uint256 userWithdraw = investment.withdraw;
        if(userWithdraw >= userDeposit){
            return 0;
        }

        Referrer storage referrer_user = referrers[_user];
        uint256 total_reward = referrer_user.totalReferrerRaward;
        if(userDeposit.sub(userWithdraw) >= referralThreshold){
            if(referrer_user.totalInvestment > 0){
                if(total_reward + referrer_user.noExtract <= referrer_user.referrerRewardLimit){
                    totalInterest += referrer_user.noExtract;
                    total_reward += referrer_user.noExtract;
                }else{
                    if(referrer_user.referrerRewardLimit > referrer_user.totalReferrerRaward){
                        totalInterest += referrer_user.referrerRewardLimit - referrer_user.totalReferrerRaward;
                        total_reward = referrer_user.referrerRewardLimit;
                    }
                }
                
                uint256 team_reward = (block.timestamp.sub(referrer_user.teamRewardTime)).mul(referrer_user.teamRewardRate);
                if(referrer_user.teamRewardTime > 0 && referrer_user.teamRewardRate > 0){
                    if(total_reward + team_reward <= referrer_user.referrerRewardLimit){
                        totalInterest += team_reward;
                    }else{
                        if(referrer_user.referrerRewardLimit > referrer_user.totalReferrerRaward){
                            totalInterest += referrer_user.referrerRewardLimit - referrer_user.totalReferrerRaward;
                        }
                    }
                }
            }
        }

        uint256 total_withdraw = investment.withdraw + totalInterest;
        uint256 transfer_amount = 0;
        if(total_withdraw >= userDeposit){
            transfer_amount = userDeposit.sub(userWithdraw); 
        }else{
            transfer_amount = totalInterest;
        }
        return transfer_amount;
    }

    function changeLockInfo(address _user, uint256 _rate, uint256 i) public onlyOwner returns (bool) {
        require(_user != address(0), "_user cannot be 0x0.");
        Lock storage userLocks = locks[_user][i];
        userLocks.releaseRate = _rate;

        emit EsgChangeLockInfo(_user, _rate, i);
        return true;
    }

    function changeInvestmentInfo(address _user, uint256 _userTotalValue, uint256 _withdraw, uint256 _lastCollectionTime) public onlyOwner returns (bool) {
        require(_user != address(0), "_user cannot be 0x0.");
        Investment storage investment = investments[_user];
        investment.userTotalValue = _userTotalValue;
        investment.withdraw = _withdraw;
        investment.lastCollectionTime = _lastCollectionTime;

        emit EsgChangeInvestmentInfo(_user, _userTotalValue, _withdraw, _lastCollectionTime);
        return true;
    }

    function changeReferrerInfo(address _user, uint256 _totalInvestment, uint256 _referrerRewardLimit, uint256 _totalReferrerRaward, uint256 _teamRewardTime, uint256 _teamRewardRate, uint256 _noExtract) public onlyOwner returns (bool) {
        require(_user != address(0), "_user cannot be 0x0.");
        Referrer storage referrer = referrers[_user];
        referrer.totalInvestment = _totalInvestment;
        referrer.referrerRewardLimit = _referrerRewardLimit;
        referrer.totalReferrerRaward = _totalReferrerRaward;
        referrer.teamRewardTime = _teamRewardTime;
        referrer.teamRewardRate = _teamRewardRate;
        referrer.noExtract = _noExtract;

        emit EsgChangeReferrerInfo(_user, _totalInvestment, _referrerRewardLimit, _totalReferrerRaward, _teamRewardTime, _teamRewardRate, _noExtract);
        return true;
    }

    function getLockInfo(address _user) public view returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        Lock[] storage userLocks = locks[_user];
        uint256 length = userLocks.length;

        uint256[] memory amounts = new uint256[](length);
        uint256[] memory esgprices = new uint256[](length);
        uint256[] memory values = new uint256[](length);
        uint256[] memory starts = new uint256[](length);
        uint256[] memory ends = new uint256[](length);
        uint256[] memory investdays = new uint256[](length);
        uint256[] memory rates = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            Lock storage lock = userLocks[i];
            amounts[i] = lock.amount;
            esgprices[i] = lock.esgPrice;
            values[i] = lock.value;
            starts[i] = lock.start;
            ends[i] = lock.end;
            investdays[i] = lock.investDays;
            rates[i] = lock.releaseRate;
        }

        return (amounts, esgprices, values, starts, ends, investdays, rates);
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}
