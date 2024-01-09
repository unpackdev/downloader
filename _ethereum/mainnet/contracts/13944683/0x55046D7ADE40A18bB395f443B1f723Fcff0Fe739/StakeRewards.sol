//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./draft-IERC20PermitUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./BumperAccessControl.sol";
import "./IStakeChangedReceiver.sol";
 
/// @notice one user's stake information 
struct StakeInfo {
    uint amount;    // amount of tokens in stake
    uint lastCI;   
    uint64 start;
    uint16 option; // selected option
    bool autorenew; // if true user don't have to do anything for continue staking
    uint64 end;
    uint64 requestedAt;
    uint claimed;
}

/// @notice period option(period in days and percentage assign with period )
struct StakeOption {
    uint total;       // amounts of stakes in each option
    uint128 emission;          // calculated emission for each option
    uint index;             // cummulative index for each option
}

/// @title Solo-staking token contract
/// @notice Staking token for one of pre-defined periods with different rewards and bonus percentage.
contract StakeRewards is Initializable, BumperAccessControl {

    using SafeERC20 for IERC20;

    function multipliers() public pure returns (uint16[4] memory) 
    { 
        return [uint16(100), uint16(150), uint16(275), uint16(600) ]; 
    }

    function periods() public pure returns (uint32[4] memory) {
        return [uint32(0), uint32(30 days), uint32(60 days), uint32(90 days)];
    }

    // store information about users stakes
    mapping(address => StakeInfo[]) public usersStake;
    // store information about stake options
    StakeOption[] public stakeOptions;

    // total emission per second for all options (5000 BUMP / day)
    uint public constant totalEmissionPerSecond = uint(5000) * uint(10**18) / 24 / 60 / 60; 

    address public stakeToken; // address of token
    uint64 public unlockTimestamp; // timestamp where this contract will unlocked
    uint32 public constant withdrawWindow = 2 days; // withdraw window for autorenew option. 
    uint32 public constant cooldownPeriod = 10 days;
    uint public lastIndexTimestamp;

    // emitted when user successfuly staked tokens
    event Staked(address sender, uint256 amount, uint256 period, bool autorenew, uint timestamp, uint16 option);

    // emitted when user successfuly claimed tokens
    event Claimed(address sender, uint256 amount, uint timestamp, uint16 option);

    // emitted when user successfuly unstaked tokens
    event Withdrawn(address sender, uint256 amount, uint256 rewards, uint timestamp, uint16 option );

    // emitted when user successfuly requested withdraw
    event WithdrawRequested(address indexed sender, uint256 amount, uint256 timestamp, uint16 option );

    modifier unlocked() {
        require(unlockTimestamp < uint64(block.timestamp), "locked");
        _;
    }

    ///@notice Will initialize state variables of this contract
    /// @param _whitelistAddresses addresses who can govern this account
    /// @param _stakeToken is staked token address
    /// @param _unlockTimestamp timestamp of end public sale period
    function initialize(
        address[] calldata _whitelistAddresses,
        address _stakeToken,
        uint64 _unlockTimestamp
    ) external initializer {
        _BumperAccessControl_init(_whitelistAddresses);
        stakeToken = _stakeToken;
        unlockTimestamp = _unlockTimestamp;

        // create stake options (it can be change later by governance)
        stakeOptions.push(StakeOption(0, 0, 0)); //  0 days, 1
        stakeOptions.push(StakeOption(0, 0, 0)); // 30 days, 1.5
        stakeOptions.push(StakeOption(0, 0, 0)); // 60 days, 2.75
        stakeOptions.push(StakeOption(0, 0, 0)); // 90 days, 6
    }

    /// -------------------  EXTERNAL, PUBLIC, VIEW, HELPERS  -------------------
    /// @notice return all user stakes
    function getUserStakes(address _account)
        public
        view
        returns (StakeInfo[] memory)
    {
        return usersStake[_account];
    }

    /// @notice return stake options array
    function getStakeOptions() public view returns (StakeOption[] memory) {
        return stakeOptions;
    }

    /// @notice returns how many tokens free
    function freeAmount() public view returns (uint256) { 
        uint total;
        for (uint16 i = 0; i < stakeOptions.length; i++) {
            total += stakeOptions[i].total;
        } 
        return
            IERC20(stakeToken).balanceOf(address(this)) - total;
    }

    /// -------------------  EXTERNAL, PUBLIC, STATE CHANGE -------------------
    /// @notice stake tokens for give option
    /// @param amount - amount of tokens
    /// @param option - index of the option in stakeOptions mapping
    /// @param autorenew - auto-renewal staking when its finished
    function stake(uint256 amount, uint16 option, bool autorenew) external unlocked {
        require(amount > 0, "!amount");
        IERC20(stakeToken).safeTransferFrom(msg.sender, address(this), amount);
        _stakeFor(amount, option, autorenew, msg.sender );
    }

    /// @notice special function for stake user token from whitelisted addresses (used for future integration with other contracts)
    /// @param amount - amount of tokens,
    /// @param option - index of the option in stakeOptions mapping
    /// @param account - address of user account
    /// @param autorenew - auto-renewal staking when its finished
    function stakeFor(
        uint256 amount,
        uint16 option,
        address account,
        bool autorenew
    ) external {
        require(amount > 0, "!amount");
        IERC20(stakeToken).safeTransferFrom(msg.sender, address(this), amount);        
        _stakeFor(amount, option, autorenew, account);
    }

    /// @notice stake tokens using permit flow
    /// @param amount - amount of tokens,
    /// @param option - index of the option in stakeOptions mapping
    /// @param autorenew - auto-renewal staking when its finished
    /// @param deadline - deadline for permit    
    /// @param v - permit v
    /// @param r - permit r
    /// @param s - permit s
    function stakeWithPermit(
        uint256 amount,
        uint16 option,
        bool autorenew,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external unlocked {
        require(amount > 0, "!amount");
        IERC20Permit(stakeToken).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        IERC20(stakeToken).safeTransferFrom(msg.sender, address(this), amount);
        _stakeFor(amount, option, autorenew, msg.sender);        
    }

    /// @notice internal function for stake logic implementation (without transfer tokens)
    /// @param amount - amount of tokens,
    /// @param option - index of the option in stakeOptions mapping
    /// @param account - address of user account
    function _stakeFor(
        uint256 amount,
        uint16 option,
        bool autorenew,
        address account
    ) internal {
        require(option < stakeOptions.length, "!option");

        _updateIndexes();

        StakeOption storage opt = stakeOptions[option];

        StakeInfo memory newStake = StakeInfo(
            amount,
            opt.index,
            uint64(block.timestamp),
            option,
            autorenew,
            autorenew ? 0 : uint64(block.timestamp + periods()[option]),
            0,
            0
        );

        usersStake[account].push(newStake);
        opt.total += amount;

        _updateEmissions();

        emit Staked(account, amount, periods()[option]/1 days, autorenew, block.timestamp, option );
    }

    /// @notice withdraw tokens
    /// @param stakeIndex - index in users stakes array
    function withdraw(uint16 stakeIndex) external unlocked {
        StakeInfo[] storage stakeInfoList = usersStake[msg.sender];       
        require(stakeInfoList.length > stakeIndex, "!index");

        _updateIndexes();

        StakeInfo memory s = stakeInfoList[stakeIndex];
        StakeOption storage opt = stakeOptions[s.option];
        (uint rewards, , bool withdrawable,) = calcRewards(s, opt);
        require(withdrawable, "!withdraw" );

        // reduce amount of option
        opt.total -= s.amount;

        // get amount to withdraw
        uint256 amountToWithdraw = s.amount + rewards;

        // remove stake from the user stakes array
        stakeInfoList[stakeIndex] = stakeInfoList[stakeInfoList.length - 1];
        stakeInfoList.pop();

        // transfer tokens to user
        IERC20(stakeToken).safeTransfer(msg.sender, amountToWithdraw);

        _updateEmissions();

        emit Withdrawn( msg.sender, s.amount, rewards, block.timestamp, stakeIndex );
    }

    /// @notice set autorenew
    function switchAutorenew(uint16 stakeIndex) external unlocked {
        StakeInfo[] storage stakeInfoList = usersStake[msg.sender];
        require(stakeInfoList.length > stakeIndex, "!index");
        StakeInfo storage s = stakeInfoList[stakeIndex];

        if (s.autorenew) {
            uint64 numOfperiods = uint64(block.timestamp - s.start) / periods()[s.option] + 1;
            s.end = s.start + numOfperiods * periods()[s.option];
            s.autorenew = false;     
        }
        else {
            require( block.timestamp < s.start + periods()[s.option], "end" );
            s.end = 0;
            s.autorenew = true;
        }
    }

    /// @notice claim rewards for the stake
    function claimRewards(uint16 stakeIndex) external unlocked {
        StakeInfo[] storage stakeInfoList = usersStake[msg.sender];
        require(stakeInfoList.length > stakeIndex, "!index");
        StakeInfo storage s = stakeInfoList[stakeIndex];

        StakeOption memory opt = stakeOptions[s.option];
        opt.index = calculateCumulativeIndex(s.option);
        (uint rewards, bool claimable, , ) = calcRewards(s, opt);
        require( claimable && rewards > 0, "!rewards" );

        s.claimed += rewards;

        IERC20(stakeToken).safeTransfer(msg.sender, rewards);

        emit Claimed(msg.sender, rewards, block.timestamp, stakeIndex );
    }
    
    /// @notice calculate rewards and check if user can claim/withdraw tokens
    function calcRewards(StakeInfo memory s, StakeOption memory opt) public view returns (uint rewards, bool claimable, bool withdrawable, uint endOfLastPeriod) {

        rewards = (opt.index - s.lastCI) * s.amount / 10**18; 

        if (periods()[s.option] == 0) { // flexible staking
            endOfLastPeriod = block.timestamp;
            claimable = rewards > 0;
            withdrawable = block.timestamp > (s.requestedAt + cooldownPeriod) && 
                block.timestamp < (s.requestedAt + cooldownPeriod + withdrawWindow);
        }
        else if (s.autorenew) { 
            uint numOfPeriods = (block.timestamp - s.start) / periods()[s.option];  
            endOfLastPeriod = s.start + (numOfPeriods * periods()[s.option]);
            withdrawable = block.timestamp > endOfLastPeriod && block.timestamp < endOfLastPeriod + withdrawWindow;
        }
        else { // no autorenew and option with lockup period
            endOfLastPeriod = s.end;

            if (block.timestamp > s.end) {
                uint extraTime = block.timestamp - s.end;
                uint extraRewards = rewards * extraTime / (s.end - s.start + extraTime);
                rewards -= extraRewards;
            }
            withdrawable = block.timestamp > s.end;
        }
        if (rewards > s.claimed)
            rewards -= s.claimed;
        else
            rewards = 0;
            
        claimable = rewards > 0;
    }
    
    /// @notice calculate rewards by index of stake
    function calcRewardsByIndex(uint16 stakeIndex) public view returns (uint rewards, bool claimable, bool withdrawable, uint endOfLastPeriod) {
        StakeInfo memory s = usersStake[msg.sender][stakeIndex];
        StakeOption memory opt = stakeOptions[ s.option ];
        opt.index = calculateCumulativeIndex(s.option);
        (rewards,claimable,withdrawable,endOfLastPeriod) = calcRewards( s, opt );
    }

    /// @notice Restake tokens of given stake to new stake with given option with or without rewards
    function restake(uint16 stakeIndex, uint16 option, bool withRewards, bool autorenew) external  unlocked
    {
        require(option < stakeOptions.length, "!option");
        require(stakeIndex < usersStake[msg.sender].length, "!index");

        _updateIndexes();

        StakeInfo memory s = usersStake[msg.sender][stakeIndex];
        StakeOption memory opt = stakeOptions[s.option];
        (uint rewards, , bool withdrawable, ) = calcRewards(s,opt);
        require(withdrawable, "!withdraw");

        stakeOptions[s.option].total -= s.amount;

        uint amount = s.amount + (withRewards ? rewards : 0);        
        StakeInfo memory newStake = StakeInfo(
            amount,
            stakeOptions[option].index,
            uint64(block.timestamp),
            option,
            autorenew,
            autorenew ? 0 : uint64( block.timestamp + periods()[s.option]),
            0,
            0
        );

        usersStake[msg.sender][stakeIndex] = newStake;

        stakeOptions[option].total += amount;

        if (!withRewards){
            IERC20(stakeToken).safeTransfer(msg.sender, rewards);
        }

        _updateEmissions();

        emit Staked(msg.sender, amount, periods()[newStake.option], autorenew, block.timestamp, option );        
    }

    /// @notice create a request to withdraw tokens from stake
    /// @dev must be call before withdraw function 
    function requestWithdraw(uint16 stakeIndex) external unlocked { 
        require(stakeIndex < usersStake[msg.sender].length, "!index");
        StakeInfo storage s = usersStake[msg.sender][stakeIndex];
        require(s.option == 0, "!option");
        require(block.timestamp > s.requestedAt + cooldownPeriod, "requested" );

        s.requestedAt = uint64(block.timestamp);

        emit WithdrawRequested(msg.sender, s.amount, block.timestamp, stakeIndex );
    }

    /// @notice calculate total weithed amount of tokens in all options
    function totalWeigthedAmount() public view returns (uint weithedAmountSum) {
        for (uint16 i = 0; i < stakeOptions.length; i++) {
            weithedAmountSum += multipliers()[i] * stakeOptions[i].total;
        }
    }

    /// @notice calculate total amount of tokens in all options
    function totalAmount() public view returns (uint amount, uint weithedAmountSum) {
        weithedAmountSum = totalWeigthedAmount();
        for (uint16 i = 0; i < stakeOptions.length; i++) {
            amount += stakeOptions[i].total;
        } 
    }
    /// @notice calculate current emission rate per second by staked amount of tokens (it can be more than fact emission because of users can unstake with delay)
    function _updateIndexes() internal {
        for (uint16 i = 0; i < stakeOptions.length; i++) {
            stakeOptions[i].index = calculateCumulativeIndex(i);
        }
        lastIndexTimestamp = block.timestamp;
    }

    /// @notice calculate current emission rate per second by staked amount of tokens (it can be more than fact emission because of users can unstake with delay)
    function _updateEmissions() internal {
        uint weigthedAmountSum = totalWeigthedAmount();
        uint16[4] memory m = multipliers();
        for (uint16 i = 0; i < stakeOptions.length; i++) {
            StakeOption storage option = stakeOptions[i];
            if (weigthedAmountSum > 0) {
                option.emission = uint64(totalEmissionPerSecond  * (option.total * m[i]) / weigthedAmountSum);
            }
            else 
                option.emission = 0;
        }
    }

    /// @notice Calculate cumulative index
    /// @param option option index
    function calculateCumulativeIndex(
        uint16 option
    ) public view returns (uint index) {
        StakeOption storage opt = stakeOptions[option];
        if (opt.total > 0) {
            index = opt.index + (block.timestamp - lastIndexTimestamp) * opt.emission * 10**18 /opt.total;
        } else {
            index = opt.index;
        }
    }

    /// @notice update unlock timestamp when the contract will go live
    function updateUnlockTimestamp(uint64 _timestamp) external onlyGovernanceOrOwner {
        require(_timestamp > 0, "!timestamp");
        unlockTimestamp = _timestamp;
    }

    /// @notice emergency withdraw tokens from the contract
    /// @param token - address of the token
    /// @param amount - amount to withdraw
    function withdrawExtraTokens(address token, uint256 amount)
        external
        onlyGovernanceOrOwner
    {
        if (token == stakeToken) {
            require(amount <= freeAmount(), "!free");
        }
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    /// @notice Pause staking contract
    /// @dev Only owner of the staking can invoke this function.
    function pause() 
        external
        onlyGovernanceOrOwner 
    {
        unlockTimestamp = type(uint64).max;
    }

    /// @notice Unpause staking contract
    /// @dev Only owner of the staking can invoke this function.
    function unpause() 
        external
        onlyGovernanceOrOwner 
    {
        unlockTimestamp = 0;
    }
}