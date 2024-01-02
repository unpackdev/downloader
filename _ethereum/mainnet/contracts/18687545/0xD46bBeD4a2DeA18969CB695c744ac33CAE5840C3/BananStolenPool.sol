//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**

     _______.___________.  ______    __       _______ .__   __. .______     ______     ______    __      
    /       |           | /  __  \  |  |     |   ____||  \ |  | |   _  \   /  __  \   /  __  \  |  |     
   |   (----`---|  |----`|  |  |  | |  |     |  |__   |   \|  | |  |_)  | |  |  |  | |  |  |  | |  |     
    \   \       |  |     |  |  |  | |  |     |   __|  |  . `  | |   ___/  |  |  |  | |  |  |  | |  |     
.----)   |      |  |     |  `--'  | |  `----.|  |____ |  |\   | |  |      |  `--'  | |  `--'  | |  `----.
|_______/       |__|      \______/  |_______||_______||__| \__| | _|       \______/   \______/  |_______|
                                                                                                         
Dapp: https://www.jungle-protocol.com/
Telegram: https://t.me/Jungle_Protocol
Twitter: https://twitter.com/Jungle_Protocol
 */

import "./IERC20.sol";
import "./AccessControl.sol";
import "./Math.sol";
import "./ReentrancyGuard.sol";
import "./IConfig.sol";
import "./IAttackRewardCalculator.sol";
import "./IBanansToken.sol";

/**
StolenPool: where the stolen banans go
- claim tax (monkeys stealing banans) from bananChef are deposited here
- every deposit is grouped into an epoch (1 day) based on time of deposit
- monkey attacks during this epoch are weighted by tier and stake claim to a portion of the epoch's deposited banans
- epoch ends, rewards are calculated, and rewards are claimable by attackers based on tier and number of successful attacks during that epoch
- rewards are claimable only for previous epochs (not current)
 */
 
contract BananStolenPool is AccessControl, ReentrancyGuard {
        
    IConfig public config;

    address public outputAddress;
    bool public poolOpenTimestampSet;
    bool public stolenPoolAttackIsOpen = false;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    uint16 public constant PERCENTAGE_DENOMINATOR = 10000;
    uint16 public attackBurnPercentage = 1000; //10%
    uint16 public monkeyTier1AttackRewardsWeight = 10000; //1x
    uint16 public monkeyTier2AttackRewardsWeight = 25000; //2.5x
    uint16 public monkeyTier3AttackRewardsWeight = 50000; //5x

    uint32 public poolOpenTimestamp; //start timestamp of bananchef pool openings = epochs start here
    
    uint32 public immutable STOLEN_POOL_EPOCH_LENGTH; //1 day in production
    
    uint32 public totalAttacks;

    uint256 public totalClaimedRewardsForAll;
    uint256 public totalBurnedFromDeposits;
    uint256 public totalBurnedFromClaims;
    uint256 public totalMinted;

    mapping(uint256 => uint256) public epochBalances;
    mapping(address => Attack[]) public userAttacks;
    mapping(uint256 => EpochAttackStats) public epochAttackStats;
    mapping(address => UserAttackStats) public userAttackStats;
    mapping(address => uint256) public manuallyAddedRewards;

    ///@dev addresses that can virtually deposit banans to this contract
    mapping(address => bool) public isApprovedDepositor;

    struct UserAttackStats {
        uint32 successfulAttacks;
        uint32 lastClaimEpoch;
        uint192 totalClaimedRewards;
    }

    struct EpochAttackStats {
        uint32 tier1;
        uint32 tier2;
        uint32 tier3;
        uint160 total;
    }

    struct Attack {
        uint216 epoch; //takes into account calcs for reward per attack by tier for this epoch (range of timestamps)
        uint32 monkeyId;
        uint8 tier;
        address user;
    }

    event AttackEvent(address indexed sender, uint256 tier);
    event StolenPoolRewardClaimed(address indexed sender, uint256 amount);
    event Deposit(address indexed sender, uint256 amount);

    error InvalidCaller(address caller, address expected);
    error CallerIsNotConfig();
    error ForwardFailed();
    error NoRewardsToClaim();
    error PoolOpenTimestampNotSet();
    error PoolOpenTimestampAlreadySet();
    error FirstEpochHasNotPassedYet(uint256 remainingTimeUntilFirstEpochPasses);
    error InvalidMonkeyTier();
    error InvalidAllowance();
    error AlreadyClaimedCurrentEpoch();

    constructor(address _configAddress, uint32 _stolenPoolEpochLength) {
        config = IConfig(_configAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        STOLEN_POOL_EPOCH_LENGTH = _stolenPoolEpochLength;
    }

    modifier approvedDepositor() {
        require(isApprovedDepositor[msg.sender], "Invalid caller");
        _;
    }

    modifier attackIsOpen() {
        require(stolenPoolAttackIsOpen, "Attack is not open");
        _;
    }

    modifier onlyConfig() {
        if (msg.sender != address(config) && !hasRole(ADMIN_ROLE,msg.sender) ) {
            revert CallerIsNotConfig();
        }
        _;
    }

    /**
     * @dev virtually deposits banans from either bananChef or monkey, 
     * assuming that the _amount has either already been burned or hasn't been minted yet
     */

    function virtualDeposit(uint256 _amount) public approvedDepositor {
        //add to this epoch's balance
        uint256 currentEpoch = getCurrentEpoch();
        epochBalances[currentEpoch] += _amount;
        totalBurnedFromDeposits += _amount;

        emit Deposit(msg.sender, _amount);
    }

    // [!] check logik - make sure cooldown is controlled from the monkey contract
    function attack(address _sender, uint256 _monkeyTier, uint256 _monkeyId) external attackIsOpen {
        //caller must be Monkey contract
        address monkeyAddress = config.monkeyAddress();
        if (msg.sender != monkeyAddress) {
            revert InvalidCaller(msg.sender, monkeyAddress);
        }

        uint256 currentEpoch = getCurrentEpoch();

        //update overall attack stats for this epoch
        if (_monkeyTier == 1) {
            ++epochAttackStats[currentEpoch].tier1;
        } else if (_monkeyTier == 2) {
            ++epochAttackStats[currentEpoch].tier2;
        } else if (_monkeyTier == 3) {
            ++epochAttackStats[currentEpoch].tier3;
        } else {
            revert InvalidMonkeyTier();
        }

        ++epochAttackStats[currentEpoch].total;
        ++totalAttacks;

        //set successful attacks for this monkey id/user and tier and epoch
        userAttacks[_sender].push(Attack(uint216(currentEpoch), uint32(_monkeyId), uint8(_monkeyTier), _sender));
        ++userAttackStats[_sender].successfulAttacks;       
        
        
        emit AttackEvent(_sender, _monkeyTier);
    }

    function claimRewards() external nonReentrant returns (uint256, uint256) {
        if(userAttackStats[msg.sender].lastClaimEpoch == uint32(getCurrentEpoch())) {
            revert AlreadyClaimedCurrentEpoch();
        }

        uint256 totalRewardsForUser = getPretaxPendingRewards(msg.sender);
        manuallyAddedRewards[msg.sender] = 0; //reset to 0 after claim

        if (totalRewardsForUser == 0) {
            revert NoRewardsToClaim();
        }

        uint256 burnAmount = Math.mulDiv(
            totalRewardsForUser,
            attackBurnPercentage,
            PERCENTAGE_DENOMINATOR
        );
        
        //update last claim epoch to current epoch to prevent double claiming
        userAttackStats[msg.sender].lastClaimEpoch = uint32(getCurrentEpoch());
        userAttackStats[msg.sender].totalClaimedRewards += uint192(totalRewardsForUser - burnAmount);
        totalClaimedRewardsForAll += totalRewardsForUser - burnAmount;        
        
        // send remaining rewards to user
        totalMinted += totalRewardsForUser - burnAmount;
        IBanansToken(config.banansAddress()).mint(msg.sender, totalRewardsForUser - burnAmount);

        // update total burned
        totalBurnedFromClaims += burnAmount;

        emit StolenPoolRewardClaimed(msg.sender, totalRewardsForUser - burnAmount);

        return (totalRewardsForUser, burnAmount);
    }

    function getCurrentEpoch() public view returns (uint256) {
        return Math.mulDiv(
            block.timestamp - poolOpenTimestamp,
            1,
            STOLEN_POOL_EPOCH_LENGTH
        );
    }

    function getEpochLength() public view returns (uint256) {
        return STOLEN_POOL_EPOCH_LENGTH;
    }

    /// @dev get seconds until next epoch
    function getSecondsUntilNextEpoch() public view returns (uint256) {
        return STOLEN_POOL_EPOCH_LENGTH - ((block.timestamp - poolOpenTimestamp) % STOLEN_POOL_EPOCH_LENGTH);
    }

    function getCurrentEpochBalance() public view returns (uint256) {
        uint256 currentEpoch = getCurrentEpoch();
        return epochBalances[currentEpoch];
    }

    function getEpochBalance(uint256 _epoch) public view returns (uint256) {
        return epochBalances[_epoch];
    }

    function getUserAttackEpochs(address _user) public view returns (uint256[] memory) {
        uint256[] memory epochs = new uint256[](userAttacks[_user].length);
        for (uint256 i = 0; i < userAttacks[_user].length; ++i) {
            epochs[i] = userAttacks[_user][i].epoch;
        }
        return epochs;
    }

    function getUserAttackMonkeyId(uint256 _index) public view returns (uint256) {
        return userAttacks[msg.sender][_index].monkeyId;
    }

    function getUserAttackTier(uint256 _index) public view returns (uint256) {
        return userAttacks[msg.sender][_index].tier;
    }

    /**
        @dev calculate user rewards by summing up rewards from each epoch
        rewards from each epoch are calculated as: baseReward = (total banans deposited this epoch) / (total successful attacks this epoch)
        where baseReward is scaled based on tier of monkey attacked such that the relative earnings are: tier 1 = 1x, tier 2 = 2.5x, tier 3 = 5x
     */
    function getPretaxPendingRewards(address _user) public view returns (uint256) {
        //claim rewards from lastClaimEpoch[_user] to currentEpoch
        uint256 currentEpoch = getCurrentEpoch();
        uint256 lastClaimedEpoch = userAttackStats[_user].lastClaimEpoch;

        uint256 totalRewardsForUser;
        for (uint256 i = lastClaimedEpoch; i < currentEpoch; ++i) {
            //get total deposited banans this epoch
            
            if(epochBalances[i] == 0) {
                continue;
            }

            (uint256 tier1RewardsPerAttack, uint256 tier2RewardsPerAttack, uint256 tier3RewardsPerAttack) = getPretaxPendingRewardsForEpoch(i);

            //now that I have the rewards per attack for each tier, I can calculate the total rewards for the user
            uint256 totalRewardCurrentEpoch = 0;
            for (uint256 j = 0; j < userAttacks[_user].length; ++j) {
                Attack memory thisAttack = userAttacks[_user][j];
                if (thisAttack.epoch == i) {
                    if (thisAttack.tier == 1) {
                        totalRewardCurrentEpoch += tier1RewardsPerAttack;
                    } else if (thisAttack.tier == 2) {
                        totalRewardCurrentEpoch += tier2RewardsPerAttack;
                    } else if (thisAttack.tier == 3) {
                        totalRewardCurrentEpoch += tier3RewardsPerAttack;
                    }
                }
            }

            totalRewardsForUser += totalRewardCurrentEpoch;
        }

        totalRewardsForUser += manuallyAddedRewards[_user];

        return totalRewardsForUser;
    }


    function getPretaxPendingRewardsForEpoch(uint256 _epoch) public view returns (uint256, uint256, uint256) {
        //get total deposited banans this epoch
        uint256 totalBanansDepositedCurrentEpoch = epochBalances[_epoch];
        EpochAttackStats memory currentEpochStats = epochAttackStats[_epoch];
        uint256 tier1Attacks = currentEpochStats.tier1;
        uint256 tier2Attacks = currentEpochStats.tier2;
        uint256 tier3Attacks = currentEpochStats.tier3;

        //get rewards per attack for each tier [tier1, tier2, tier3]
        uint256[] memory rewardsPerAttackByTier = IAttackRewardCalculator(config.attackRewardCalculatorAddress()).calculateRewardPerAttackByTier(
            tier1Attacks,
            tier2Attacks,
            tier3Attacks,
            monkeyTier1AttackRewardsWeight,
            monkeyTier2AttackRewardsWeight,
            monkeyTier3AttackRewardsWeight,
            totalBanansDepositedCurrentEpoch
        );

        return (rewardsPerAttackByTier[0], rewardsPerAttackByTier[1], rewardsPerAttackByTier[2]);
    }

    function getPosttaxPendingRewards(address _user) public view returns (uint256) {
        uint256 pretaxRewards = getPretaxPendingRewards(_user);
        uint256 posttaxRewards = Math.mulDiv(
            pretaxRewards,
            PERCENTAGE_DENOMINATOR - attackBurnPercentage,
            PERCENTAGE_DENOMINATOR
        );
        return posttaxRewards;
    }

    function getUserSuccessfulAttacks(address _user) public view returns (uint256) {
        return userAttackStats[_user].successfulAttacks;
    }

    function getUserLastClaimEpoch(address _user) public view returns (uint256) {
        return userAttackStats[_user].lastClaimEpoch;
    }

    function getUserTotalClaimedRewards(address _user) public view returns (uint256) {
        return userAttackStats[_user].totalClaimedRewards;
    }

    function getEpochTier1Attacks(uint256 _epoch) public view returns (uint256) {
        return epochAttackStats[_epoch].tier1;
    }

    function getEpochTier2Attacks(uint256 _epoch) public view returns (uint256) {
        return epochAttackStats[_epoch].tier2;
    }

    function getEpochTier3Attacks(uint256 _epoch) public view returns (uint256) {
        return epochAttackStats[_epoch].tier3;
    }

    function getEpochTotalAttacks(uint256 _epoch) public view returns (uint256) {
        return epochAttackStats[_epoch].total;
    }

    //=========================================================================
    // SETTERS/WITHDRAWALS
    //=========================================================================

    //corresponds to the call of bananChef.openBananChefDeposits()
    function setStolenPoolOpenTimestamp() external onlyConfig {
        if (!poolOpenTimestampSet) {
            //set timestamp for the start of epochs
            poolOpenTimestamp = uint32(block.timestamp);
            poolOpenTimestampSet = true;
        } else {
            revert PoolOpenTimestampAlreadySet();
        }
    }

    function setPoolOpenTimestampManual(uint32 _timestamp) external onlyRole(ADMIN_ROLE) {
        poolOpenTimestamp = _timestamp;
    }

    function setStolenPoolAttackIsOpen(bool _isOpen) external onlyConfig {
        stolenPoolAttackIsOpen = _isOpen;
    }

    function setAttackBurnPercentage(uint16 _percentage) external onlyConfig {
        attackBurnPercentage = _percentage;
    }

    function setIsApprovedDepositor(address _depositor, bool _isApproved) external onlyConfig {
        isApprovedDepositor[_depositor] = _isApproved;
    }

    //-------------------------------------------------------------------------

    function burnAndVirtualDeposit(uint256 _amount) external onlyRole(ADMIN_ROLE) {
        IBanansToken(config.banansAddress()).transferFrom(msg.sender, address(this), _amount);
        IBanansToken(config.banansAddress()).burn(_amount);
        virtualDeposit(_amount);
    }

    function setEpochBalanceManual(uint256 _epoch, uint256 _epochBalance) external onlyRole(ADMIN_ROLE) {
        epochBalances[_epoch] = _epochBalance;
    }

    function addToEpochBalanceManual(uint256 _epoch, uint256 _amount) external onlyRole(ADMIN_ROLE) {
        epochBalances[_epoch] += _amount;
    }

    function batchSetManuallyAddedRewards(address[] memory _users, uint256[] memory _amounts) external onlyRole(ADMIN_ROLE) {
        require(_users.length == _amounts.length, "Invalid input");
        for (uint256 i = 0; i < _users.length; i++) {
            manuallyAddedRewards[_users[i]] = _amounts[i];
        }
    }

    function batchAddToManuallyAddedRewards(address[] memory _users, uint256[] memory _amounts) external onlyRole(ADMIN_ROLE) {
        require(_users.length == _amounts.length, "Invalid input");
        for (uint256 i = 0; i < _users.length; i++) {
            manuallyAddedRewards[_users[i]] += _amounts[i];
        }
    }

    function setManuallyAddedRewardsForUser(address _user, uint256 _amount) public onlyRole(ADMIN_ROLE) {
        manuallyAddedRewards[_user] = _amount;
    }

    function addToManuallyAddedRewardsForUser(address _user, uint256 _amount) public onlyRole(ADMIN_ROLE) {
        manuallyAddedRewards[_user] += _amount;
    }

    //-------------------------------------------------------------------------

    function setConfigManagerAddress(address _configManagerAddress) external onlyRole(ADMIN_ROLE) {
        config = IConfig(_configManagerAddress);
    }

    function setOutputAddress(address _outputAddress) external onlyRole(ADMIN_ROLE) {
        outputAddress = _outputAddress;
    }

    function withdrawERC20FromContract(address _to, address _token) external onlyRole(ADMIN_ROLE) {
        bool os = IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
        if (!os) {
            revert ForwardFailed();
        }
    }

    function withdrawEthFromContract() external onlyRole(ADMIN_ROLE) {
        require(outputAddress != address(0), "Payment splitter address not set");
        (bool os, ) = payable(outputAddress).call{value: address(this).balance}("");
        if (!os) {
            revert ForwardFailed();
        }
    }
}