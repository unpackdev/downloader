// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ABDKMath64x64.sol";

contract stAGIX is Pausable, Ownable {
    // PRIVATE VARIABLES

    // staking periods in days
    uint64 private immutable _stakingPeriod1;
    uint64 private immutable _stakingPeriod2;

    // rewards rates correspond with staking periods, calculate as compound interest per day
    // users receive (rate * staked amount / (10**18)) tokens per staking day
    uint64 private immutable _rewardsRate1;
    uint64 private immutable _rewardsRate2;

    // tokens used for staking and rewards
    IERC20 private immutable _token;

    uint128 private _idCounter;

    // EVENTS

    event Stake(
        address indexed user,
        uint256 indexed id,
        uint256 indexed stakedAmount,
        uint256 stakingPeriod,
        uint256 startTime
    );

    event Withdraw(
        address indexed user,
        uint256 indexed id,
        uint256 stakedAmount,
        uint256 indexed withdrawAmount,
        uint256 stakingPeriod,
        uint256 startTime,
        uint256 endTime
    );

    event Claim(
        address indexed user,
        uint256 indexed id,
        uint256 indexed claimAmount
    );

    // MODIFIERS

    modifier stakingPeriodEnded(uint256 id) {
        uint256 startTime = _userStakingInfo[_msgSender()][id].startTime;
        uint256 stakingPeriod = _userStakingInfo[_msgSender()][id].stakingPeriod;
        uint256 timePassed = block.timestamp - startTime;

        require(
            timePassed / 1 days >= stakingPeriod,
            "The current staking period has not ended"
        );
        _;
    }

    modifier isClaimable(uint256 id) {
        uint256 claimed = _userStakingInfo[_msgSender()][id].claimed;

        require(claimed != 1, "The reward has already been paid.");
        _;
    }

    modifier validId(uint256 id) {
        require(
            _userStakingInfo[_msgSender()][id].stakedAmount > 0,
            "Invalid id"
        );
        _;
    }

    modifier validAmount(uint256 amount) {
        require(amount >= 10000000000, "Amount must be greater than or equal to 100");
        _;
    }

    modifier validStakingPeriod(uint256 stakingPeriod) {
        require(
            stakingPeriod == _stakingPeriod1 || stakingPeriod == _stakingPeriod2,
            "Invalid staking period"
        );
        _;
    }

    // STRUCT, MAPPING

    struct StakingInfo {
        uint256 id;
        uint256 stakedAmount;
        uint256 stakingPeriod;
        uint256 startTime;
        uint256 claimed;
    }

    mapping(address => StakingInfo[]) private _userStakingInfo;

    // CONSTRUCTOR

    constructor(
        uint64 stakingPeriod1_,
        uint64 stakingPeriod2_,
        uint64 rewardsRate1_,
        uint64 rewardsRate2_,
        IERC20 token_,
        address initialOwner
    ) Ownable(initialOwner) {
        require(
            address(token_) != address(0),
            "Token address cannot be the zero address"
        );

        _stakingPeriod1 = stakingPeriod1_;
        _stakingPeriod2 = stakingPeriod2_;
        _rewardsRate1 = rewardsRate1_;
        _rewardsRate2 = rewardsRate2_;
        _token = token_;
    }

    // STATE-CHANGING PUBLIC FUNCTIONS

    function withdrawableAmount(uint256 id) public view virtual validId(id) stakingPeriodEnded(id) returns (uint256) {
        return _withdrawableAmount(id);
    }

    function claimableAmount(uint256 id) public view virtual validId(id) isClaimable(id) returns (uint256) {
        return _claimableAmount(id);
    }

    function stake(uint256 amount, uint256 stakingPeriod) public virtual validAmount(amount) validStakingPeriod(stakingPeriod) {
        _stake(amount, stakingPeriod);
    }

    function withdraw(uint256 id) public virtual validId(id) stakingPeriodEnded(id) {
        _withdraw(id);
    }

    function claim(uint256 id) public virtual validId(id) isClaimable(id) {
        _claim(id);
    }

    function pauseStaking() public onlyOwner {
        _pause();
    }

    function unpauseStaking() public onlyOwner {
        _unpause();
    }

    // PUBLIC VIEW FUNCTIONS

    function rewardsRate1() public view virtual returns (uint256) {
        return _rewardsRate1;
    }

    function rewardsRate2() public view virtual returns (uint256) {
        return _rewardsRate2;
    }

    function token() public view virtual returns (IERC20) {
        return _token;
    }

    function idCounter() public view virtual returns (uint256) {
        return _idCounter;
    }

    function getUserStakingInfo(address user) public view virtual returns (StakingInfo[] memory) {
        return _userStakingInfo[user];
    }

    // INTERNAL FUNCTIONS

    function _stake(uint256 amount, uint256 stakingPeriod) internal whenNotPaused {
        uint256 counter = _idCounter;

        _token.transferFrom(msg.sender, address(this), amount);
        _userStakingInfo[msg.sender].push(
            StakingInfo(counter, amount, stakingPeriod, block.timestamp, 0)
        );
        unchecked {
            ++_idCounter;
        }
        emit Stake(msg.sender, counter, amount, block.timestamp, stakingPeriod);
    }

    function _withdraw(uint256 id) internal {
        StakingInfo storage stakingInfo = _userStakingInfo[msg.sender][id];
        uint256 withdrawableAmount_ = _withdrawableAmount(id);

        delete _userStakingInfo[msg.sender][id];
        _token.transfer(msg.sender, withdrawableAmount_);

        emit Withdraw(
            msg.sender,
            id,
            stakingInfo.stakedAmount,
            withdrawableAmount_,
            stakingInfo.stakingPeriod,
            stakingInfo.startTime,
            block.timestamp
        );
    }

    function _withdrawableAmount(uint256 id) internal view returns (uint256) {
        StakingInfo storage stakingInfo = _userStakingInfo[_msgSender()][id];

        uint256 stakingPeriod = stakingInfo.stakingPeriod;

        uint256 amountWhenStakingPeriodEnds = calculateCompound(
            _rewardsRate(stakingPeriod),
            stakingInfo.stakedAmount,
            stakingPeriod
        );

        if (stakingInfo.claimed == 0){
            return amountWhenStakingPeriodEnds;
        } else {
            uint256 amountWithdraw = stakingInfo.stakedAmount;

            return amountWithdraw;
        }
    }

    function _claim(uint256 id) internal {
        StakingInfo storage stakingInfo = _userStakingInfo[msg.sender][id];
        uint256 withdrawableAmount_ = _claimableAmount(id);

        _userStakingInfo[msg.sender][id] = StakingInfo(stakingInfo.id, stakingInfo.stakedAmount, stakingInfo.stakingPeriod, stakingInfo.startTime, 1);

        _token.transfer(msg.sender, withdrawableAmount_);

        emit Claim(msg.sender, id, stakingInfo.stakedAmount);
    }

    function _claimableAmount(uint256 id) internal view returns (uint256) {
        StakingInfo storage stakingInfo = _userStakingInfo[_msgSender()][id];

        uint256 stakingPeriod = stakingInfo.stakingPeriod;

        uint256 amountWhenStakingPeriodEnds = calculateCompound(
            _rewardsRate(stakingPeriod),
            stakingInfo.stakedAmount,
            stakingPeriod
        );

        uint256 amountClaim = amountWhenStakingPeriodEnds - stakingInfo.stakedAmount;

        return amountClaim;
    }

    function _rewardsRate(uint256 stakingPeriod) internal view returns (uint256) {
        if (stakingPeriod == _stakingPeriod1) {
            return  _rewardsRate1;
        } else if (stakingPeriod == _stakingPeriod2) {
            return  _rewardsRate2;
        }
        
        revert("Invalid staking period rate");
    }

    // ratio is the staking rewards rate
    // principle is the staked amount
    // n is staking days
    function calculateCompound(uint256 ratio, uint256 principal, uint256 n) public pure returns (uint256) {
        return
            ABDKMath64x64.mulu(
                ABDKMath64x64.pow(
                    ABDKMath64x64.add(
                        ABDKMath64x64.fromUInt(1),
                        ABDKMath64x64.divu(ratio, 10 ** 18)
                    ),
                    n
                ),
                principal
            );
    }
}