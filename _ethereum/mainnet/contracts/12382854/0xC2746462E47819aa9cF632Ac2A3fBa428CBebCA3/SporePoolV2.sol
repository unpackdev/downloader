pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";

import "./Defensible.sol";
import "./IMushroomFactory.sol";
import "./IMission.sol";
import "./ISporeToken.sol";
import "./BannedContractList.sol";

contract SporePoolV2 is OwnableUpgradeSafe, ReentrancyGuardUpgradeSafe, PausableUpgradeSafe, Defensible {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    ISporeToken public sporeToken;
    IERC20 public stakingToken;
    uint256 public sporesPerSecond = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256 public constant MAX_PERCENTAGE = 100;
    uint256 public devRewardPercentage;
    address public devRewardAddress;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;

    IMushroomFactory public mushroomFactory;
    IMission public mission;
    BannedContractList public bannedContractList;

    uint256 public stakingEnabledTime;

    uint256 public votingEnabledTime;
    uint256 public nextVoteAllowedAt;
    uint256 public lastVoteNonce;
    uint256 public voteDuration;

    address public enokiDaoAgent;

    // In percentage: mul(X).div(100)
    uint256 public decreaseRateMultiplier;
    uint256 public increaseRateMultiplier;

    mapping(address => bool) rewardHarvested;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _sporeToken,
        address _stakingToken,
        address _mushroomFactory,
        address _mission,
        address _bannedContractList,
        address _devRewardAddress,
        address daoAgent_,
        uint256[5] memory uintParams
    ) virtual public initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Ownable_init_unchained();

        sporeToken = ISporeToken(_sporeToken);
        stakingToken = IERC20(_stakingToken);
        mushroomFactory = IMushroomFactory(_mushroomFactory);
        mission = IMission(_mission);
        bannedContractList = BannedContractList(_bannedContractList);

        decreaseRateMultiplier = 50;
        increaseRateMultiplier = 150;

        /*
            [0] uint256 _devRewardPercentage,
            [1] uint256 stakingEnabledTime_,
            [2] uint256 votingEnabledTime_,
            [3] uint256 voteDuration_,
            [4] uint256 initialRewardRate_,
        */

        sporesPerSecond = uintParams[4];

        devRewardPercentage = uintParams[0];
        devRewardAddress = _devRewardAddress;

        stakingEnabledTime = uintParams[1];
        votingEnabledTime = uintParams[2];
        nextVoteAllowedAt = uintParams[2];
        voteDuration = uintParams[3];
        lastVoteNonce = 0;

        enokiDaoAgent = daoAgent_;
    }

    /* ========== VIEWS ========== */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    // Rewards are turned off at the mission level
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        // Time difference * sporesPerSecond
        return rewardPerTokenStored.add(lastTimeRewardApplicable().sub(lastUpdateTime).mul(sporesPerSecond).mul(1e18).div(_totalSupply));
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external virtual nonReentrant defend(bannedContractList) whenNotPaused updateReward(msg.sender) {
        revert("Staking disabled");
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    // withdraw+harvest
    function withdraw(uint256 amount) public virtual nonReentrant updateReward(msg.sender) {
        // In case the stake is 0 or the amount is less than the balance,
        // ensure the function is reenterable
        if (amount > 0) {
            _totalSupply = _totalSupply.sub(amount);
            _balances[msg.sender] = _balances[msg.sender].sub(amount);
            stakingToken.safeTransfer(msg.sender, amount);
            emit Withdrawn(msg.sender, amount);
        }
        // do not call blindly as harvest can
        // revert the results of safeTransfer above
        if (!rewardHarvested[msg.sender]) {
            harvest(0);
        }
    }

    // execute by calling withdraw
    function harvest(uint256 mushroomsToGrow) internal /*nonReentrant updateReward(msg.sender)*/ {
        require(mushroomsToGrow == 0, "Growing mushrooms is disabled");
        require(!rewardHarvested[msg.sender], "Reward already harvested");

        uint256 reward = rewards[msg.sender];

        if (reward > 0) {
            uint256 remainingReward = reward;
            rewards[msg.sender] = 0;

            // Burn some rewards for mushrooms if desired
            if (mushroomsToGrow > 0) {
                uint256 totalCost = mushroomFactory.costPerMushroom().mul(mushroomsToGrow);

                require(
                    mushroomsToGrow <= mushroomFactory.getRemainingMintableForMySpecies(mushroomsToGrow),
                    "Number of mushrooms specified exceeds cap"
                );
                require(reward >= totalCost, "Not enough rewards to grow the number of mushrooms specified");

                uint256 toDev = totalCost.mul(devRewardPercentage).div(MAX_PERCENTAGE);

                if (toDev > 0) {
                    mission.sendSpores(devRewardAddress, toDev);
                }

                mission.sendSpores(enokiDaoAgent, totalCost.sub(toDev));

                remainingReward = reward.sub(totalCost);
                mushroomFactory.growMushrooms(msg.sender, mushroomsToGrow);
            }

            if (remainingReward > 0) {
                // TODO: Add safe ERC20 features to spore token
                // sporeToken.safeTransfer(msg.sender, remainingReward);
                uint256 oneMonthReward = 2_592_000 * sporesPerSecond;
                uint256 limitedReward = 
                    (oneMonthReward > remainingReward)?
                    remainingReward : oneMonthReward;

                rewardHarvested[msg.sender] = true;

                mission.sendSpores(msg.sender, limitedReward);
                emit RewardPaid(msg.sender, limitedReward);
            }
        }
    }

    // Withdraw, forfietting all rewards
    function emergencyWithdraw() external {
        withdraw(_balances[msg.sender]);
    }

    /*
        Votes with a given nonce invalidate other votes with the same nonce
        This ensures only one rate vote can pass for a given time period
    */

    function reduceRate(uint256 voteNonce) public onlyDAO {
        require(now >= votingEnabledTime, "SporePool: Voting not enabled yet");
        require(now >= nextVoteAllowedAt, "SporePool: Previous rate change vote too soon");
        require(voteNonce == lastVoteNonce.add(1), "SporePool: Incorrect vote nonce");

        sporesPerSecond = sporesPerSecond.mul(decreaseRateMultiplier).div(MAX_PERCENTAGE);

        nextVoteAllowedAt = now.add(voteDuration);
        lastVoteNonce = voteNonce.add(1);
    }

    function increaseRate(uint256 voteNonce) public onlyDAO {
        require(now >= votingEnabledTime, "SporePool: Voting not enabled yet");
        require(now >= nextVoteAllowedAt, "SporePool: Previous rate change vote too soon");
        require(voteNonce == lastVoteNonce.add(1), "SporePool: Incorrect vote nonce");

        // Multiple by 1.5x
        sporesPerSecond = sporesPerSecond.mul(increaseRateMultiplier).div(MAX_PERCENTAGE);

        nextVoteAllowedAt = now.add(voteDuration);
        lastVoteNonce = voteNonce.add(1);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        // Cannot recover the staking token or the rewards token
        require(tokenAddress != address(stakingToken) && tokenAddress != address(sporeToken), "Cannot withdraw the staking or rewards tokens");

        //TODO: Add safeTransfer
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyDAO {
        require(msg.sender == enokiDaoAgent, "SporePool: Only Enoki DAO agent can call");
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Recovered(address token, uint256 amount);
}
