// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

contract StakingContract is Ownable {
    IERC20 public token; // The ERC20 token to be staked
    uint256 public minStakeAmount; // Minimum stake amount required
    uint256 public cooldownPeriod; // Cooldown period for unstaking (in seconds)
    bool public isStakingPhaseActive;   
    bool public isVotingPhaseActive;
    bool public isUnstakingPhaseActive;

    struct StakingData {
        uint256 stakedBalance;
        bool hasStaked;
        bool canUnstake;
        uint256 unstakeTimestamp;
    }

    mapping(address => StakingData) public stakingInfo;


    // Events
    event TokenStaked(address indexed beneficiary, uint256 indexed amount, uint256 indexed timestamp);
    event TokensUnstaked(address indexed beneficiary, uint256 indexed amount, uint256 indexed timestamp);
    event UnStakeSelected(address indexed user, uint256 indexed timestamp);
    event VotingStarted(uint256 indexed timestamp);
    event InitialState(uint256 indexed timestamp);
    event UnStakeStarted(uint256 indexed timestamp);
    event StakeStarted(uint256 indexed timestamp);
    event CooldownPeriodUpdated(uint256 indexed newCooldownPeriod, uint256 indexed timestamp);
    event MinStakeAmountUpdated(uint256 indexed newMinStakeAmount, uint256 indexed timestamp);


    constructor(
        address _token,
        uint256 _minStakeAmount,
        uint256 _cooldownPeriod
    ) {
        token = IERC20(_token);
        minStakeAmount = _minStakeAmount * 1 ether;
        cooldownPeriod = _cooldownPeriod;
    }

    /**
    * @dev Allows the contract owner to set the initial state of the contract phases.
    * This function can be used for testing and initializing the contract.
    * @notice This function should only be accessible to the contract owner.
    */
    function setInitialState() external onlyOwner{
        isStakingPhaseActive = false;
        isVotingPhaseActive = false;
        isUnstakingPhaseActive = false;

       emit InitialState(block.timestamp);
    }

    /**
    * @dev Allows the contract owner to start the staking phase.
    * During the staking phase, users can stake their tokens.
    * @notice This function should only be accessible to the contract owner.
    */
    function startStake() external onlyOwner {
        require(!isStakingPhaseActive, "StakingContract: Staking is already active.");
        require(!(isUnstakingPhaseActive || isVotingPhaseActive), "StakingContract: Unstaking or Voting phase is active, cannot start staking.");
        isStakingPhaseActive = true;

       emit StakeStarted(block.timestamp);
    }

    /**
    * @dev Allows the contract owner to start the voting phase.
    * During the voting phase, users cannot stake, and voting-related activities are enabled.
    * @notice This function should only be accessible to the contract owner.
    * @dev Throws an error if the voting phase is already active.
    */
    function startVoting() external onlyOwner {
        require(isStakingPhaseActive, "StakingContract: Staking is not active.");
        require(!isVotingPhaseActive, "StakingContract: Voting is already active.");
        require(!isUnstakingPhaseActive, "StakingContract: Voting can not be started during unstaking phase.");
        isStakingPhaseActive = false;
        isVotingPhaseActive = true;

        emit VotingStarted(block.timestamp);
    }

    /**
    * @dev Allows the contract owner to start the unstaking phase.
    * During the unstaking phase, users can select to unstake their tokens.
    * @notice This function should only be accessible to the contract owner.
    * @dev Throws an error if the voting phase is not active.
    */
    function startUnstake() external onlyOwner {
        require(!isUnstakingPhaseActive, "StakingContract: Unstake phase is already active");
        require(isVotingPhaseActive, "StakingContract: Voting phase has not started yet.");
        isVotingPhaseActive = false;
        isUnstakingPhaseActive = true;

        emit UnStakeStarted(block.timestamp);
    }
    /**
    * @dev Allows users to stake their tokens during the staking phase.
    * Users can only stake when the staking phase is active.
    * If the user has not staked before, they must meet the minimum stake requirement.
    * @param _amount The amount of tokens to stake.
    */
    function stake(uint256 _amount) external  {
        require(isStakingPhaseActive, "StakingContract:You can only stake when staking phase is active.");
        require(_amount > 0, "StakingContract: Cannot stake zero tokens");
        StakingData storage staker = stakingInfo[msg.sender];

        if (!staker.hasStaked) {
            require(_amount >= minStakeAmount, "StakingContract:You must stake at least the minimum amount");
            staker.hasStaked = true;
        }
       // Transfer tokens from the user to this contract
        token.transferFrom(msg.sender, address(this), _amount);
        // Update the staked balance for the user
        staker.stakedBalance += _amount;

        emit TokenStaked(msg.sender, _amount, block.timestamp);
}


    /**
    * @dev Allows users to select to unstake their tokens during the unstaking phase.
    * Users can only select to unstake when the unstaking phase is active and they have staked tokens.
    * Users can only select to unstake once.
    * @notice This function is called by users when they want to initiate the unstaking process.
    */
    function selectUnstake() external {
        
        StakingData storage staker = stakingInfo[msg.sender];

        require(!staker.canUnstake, "StakingContract: Already selected unstaking");
        require(isUnstakingPhaseActive, "StakingContract: Unstake phase is not active yet!");
        require(staker.stakedBalance != 0, "StakingContract: You must have staked tokens to begin unstaking.");

        staker.canUnstake = true;
        staker.unstakeTimestamp = block.timestamp;

        emit UnStakeSelected(msg.sender, block.timestamp);
    }
    
    /**
    * @dev Allows users to complete the unstaking process and retrieve their staked tokens.
    * Users must have previously selected to unstake, and the cooldown period must have passed.
    */
    function unstake() external  {
        StakingData storage staker = stakingInfo[msg.sender];
        require(staker.canUnstake, "StakingContract: You must choose to unstake first.");
        require(block.timestamp >= staker.unstakeTimestamp + cooldownPeriod, "StakingContract: The Cool down period has not yet passed."); 
        uint256 amountToUnstake = staker.stakedBalance;
        
        staker.stakedBalance = 0;
        staker.canUnstake = false;
        
        // Transfer staked tokens back to the user
        token.transfer(msg.sender, amountToUnstake);

        emit TokensUnstaked(msg.sender, amountToUnstake, block.timestamp);
    }


    /**
    * @dev Allows the contract owner to update the minimum stake amount required.
    * The new minimum stake amount must be greater than zero and different from the current value.
    * @param _newMinStakeAmount The new minimum stake amount.
    * @notice This function should only be accessible to the contract owner.
    */
    function updateMinStakeAmount(uint256 _newMinStakeAmount) external onlyOwner {
        require(_newMinStakeAmount != 0 && _newMinStakeAmount < minStakeAmount, "StakingContract: Invalid new minimum stake amount.");
        minStakeAmount = _newMinStakeAmount;

        emit MinStakeAmountUpdated(_newMinStakeAmount,block.timestamp);
    }

    /**
    * @dev Allows the contract owner to update the cooldown period for unstaking.
    * The new cooldown period must be different from the current value and greater than zero.
    * @param _newCooldownPeriod The new cooldown period in seconds.
    * @notice This function should only be accessible to the contract owner.
    */
    function updateCooldownPeriod(uint256 _newCooldownPeriod) external onlyOwner {
        require(_newCooldownPeriod != cooldownPeriod, "StakingContract: New cool down period must be different from the current value.");
        require(_newCooldownPeriod != 0, "Cooldown period must be greater than zero");
        cooldownPeriod = _newCooldownPeriod;

        emit CooldownPeriodUpdated(_newCooldownPeriod, block.timestamp);
    }

    /**
    * @dev Retrieves the staked token balance of a specific account.
    * @param account The address of the account for which to retrieve the staked balance.
    * @return The staked token balance of the specified account.
    */
    function balanceOf(address account) external view returns (uint256) {
        return stakingInfo[account].stakedBalance;
    }

    /**
    * @dev Retrieves the remaining time until a user can complete the unstaking process.
    * Users can only call this function after selecting to unstake.
    * @param user The address of the user for whom to calculate the time left to unstake.
    * @return The remaining time in seconds until the cooldown period ends. Returns 0 if the cooldown period has already passed.
    */
    function getTimeLeftToUnstake(address user) external view returns (uint256) {
        StakingData storage staker = stakingInfo[user];
        require(staker.canUnstake, "StakingContract: Unstake not selected.");

        uint256 unstakeTime = staker.unstakeTimestamp;
        uint256 currentTime = block.timestamp;
        
        // Calculate the remaining time until the cooldown period ends
        if (unstakeTime + cooldownPeriod > currentTime) {
            return unstakeTime + cooldownPeriod - currentTime;
        } else {
            return 0; // The cooldown period has already passed
        }
    }

    /**
    * @dev Retrieves the current state of the contract.
    * The state can be one of the following: "Voting State," "UnStake State," "Staking State," or "Initial State."
    * @return A string indicating the current state of the contract.
    */
    function getCurrentState() external view returns (string memory) {
        if (isVotingPhaseActive) {
            return "Voting State";
        } else if (isUnstakingPhaseActive) {
            return "UnStake State";
        } else if (isStakingPhaseActive) {
            return "Staking State";
        }else {
            return "Initial State";
        }
    }

    
}
