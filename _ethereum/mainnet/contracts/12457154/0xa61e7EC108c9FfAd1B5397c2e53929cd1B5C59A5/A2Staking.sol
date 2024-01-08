// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Context.sol";

contract A2Staking is Context, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event PoolAdded(uint256 indexed poolId, address indexed token, uint256 cliff, uint256 duration, uint256 penalty);
    event PoolClosed(uint256 indexed poolId);

    event Staked(address indexed token, uint256 indexed pool, address indexed beneficiary, uint256 stake, uint256 stakeAmount, uint256 duration);
    event Unstaked(address indexed token, uint256 indexed pool, address indexed beneficiary, uint256 stake, uint256 unstakeAmount, uint256 penalty);

    uint256 private constant EXP = 1e18;

    struct Pool {
        IERC20 token;               // Token of the pool
        uint256 cliff;              // Period when unstake is prohibited
        uint256 duration;           // Stake duration (including cliff)
        uint256 penalty;            // Penalty of early unstake calculated as amount * penalty / EXP
        bool closed;                // Closed pool is no longer available for new stakes, only unstake allowed
        uint256 tvl;                // Total amount of tokens locked in this pool
    }

    struct Stake {
        uint256 start;
        uint256 amount;
    }

    Pool[] public pools;
    mapping(address => mapping(uint256 => Stake[])) public stakes;
    address public penaltyBeneficiary;

    constructor() {
        penaltyBeneficiary = owner();
    }

    function addPool(IERC20 token, uint256 cliff, uint256 duration, uint256 penalty) external onlyOwner returns(uint256) {
        require(penalty < EXP, "penalty >= 100%");
        require(duration >= cliff, "wrong duration");
        uint256 poolId = pools.length;
        pools.push(Pool({
            token: token,
            cliff: cliff,
            duration: duration,
            penalty:penalty,
            closed:false,
            tvl: 0
        }));
        emit PoolAdded(poolId, address(token), cliff, duration, penalty);
        return poolId;
    }

    function closePool(uint256 poolId) external onlyOwner {
        Pool storage pool = pools[poolId];
        require(address(pool.token) != address(0), "pool not found");
        require(!pool.closed, "already closed");
        pool.closed = true;
        emit PoolClosed(poolId);
    }

    function setPenaltyBeneficiary(address _penaltyBeneficiary) external onlyOwner {
        penaltyBeneficiary = _penaltyBeneficiary;
    }

    function stake(uint256 poolId, uint256 amount) external {
        stakeInternal(_msgSender(), poolId, amount);
    }

    function stakeFor(address beneficiary, uint256 poolId, uint256 amount) external {
        stakeInternal(beneficiary, poolId, amount);
    }

     /**
     * @notice Unstake from specific stake
     * @param poolId Pool to unstake from
     * @param stakeId Stake to unstake from
     * @param amount Amount to unstake
     */
    function unstakeExactStake(uint256 poolId, uint256 stakeId, uint256 amount) external {
        unstakeExactStakeInternal(_msgSender(), poolId, stakeId, amount);
    }

    /**
     * @notice Unstake from specific stakes
     * @param poolId Pool to unstake from
     * @param stakeIds Array of stake ids to use for unstake, must be sorted in ascending order
     * @param amounts Array of amounts corresponding to stake ids
     */
    function unstakeExactStakes(uint256 poolId, uint256[] calldata stakeIds, uint256[] calldata amounts) external {
        require(stakeIds.length == amounts.length, "arrays length mismatch");
        unstakeExactStakesInternal(_msgSender(), poolId, stakeIds, amounts);
    }

    function userStakesAndPenalties(address beneficiary, uint256 poolId) external view
    returns(uint256[] memory stakeStarts, uint256[] memory stakeAmounts, uint256[] memory penalties) {
        Pool storage pool = pools[poolId];
        require(address(pool.token) != address(0), "pool not found");
        Stake[] storage userStakes = stakes[beneficiary][poolId];

        stakeStarts = new uint256[](userStakes.length);
        stakeAmounts = new uint256[](userStakes.length);
        penalties = new uint256[](userStakes.length);

        for(uint256 i=0; i<userStakes.length; i++) {
            Stake storage stakee = userStakes[i];
            stakeStarts[i] = stakee.start;
            stakeAmounts[i] = stakee.amount;
            uint256 penaltieForFullUnstake = calculateUnstakePenalty(pool, stakee, stakee.amount);
            if (penaltieForFullUnstake == 0) {
                penalties[i] = 0;    
            } else if(penaltieForFullUnstake == stakee.amount) {
                penalties[i] = EXP;
            } else {
                penalties[i] = penaltieForFullUnstake.mul(EXP).div(stakee.amount);
            }
        }
    }

    function allUserStakesAndPenalties(address beneficiary) external view
    returns(uint256[] memory stakePools, uint256[] memory stakeIds, uint256[] memory stakeStarts, uint256[] memory stakeAmounts, uint256[] memory penalties) {
        uint256 totalStakes;
        for(uint256 p=0; p<pools.length; p++){
            totalStakes += stakes[beneficiary][p].length;
        }
        
        stakePools = new uint256[](totalStakes);
        stakeIds = new uint256[](totalStakes);
        stakeStarts = new uint256[](totalStakes);
        stakeAmounts = new uint256[](totalStakes);
        penalties = new uint256[](totalStakes);

        uint256 idx;
        for(uint256 p=0; p<pools.length; p++){
            Stake[] storage userStakes = stakes[beneficiary][p];
            if(userStakes.length == 0) continue;

            Pool storage pool = pools[p];
            for(uint256 i=0; i<userStakes.length; i++) {
                Stake storage stakee = userStakes[i];
                stakePools[idx] = p;
                stakeIds[idx] = i;
                stakeStarts[idx] = stakee.start;
                stakeAmounts[idx] = stakee.amount;
                uint256 penaltieForFullUnstake = calculateUnstakePenalty(pool, stakee, stakee.amount);
                if (penaltieForFullUnstake == 0) {
                    penalties[idx] = 0;    
                } else if(penaltieForFullUnstake == stakee.amount) {
                    penalties[idx] = EXP;
                } else {
                    penalties[idx] = penaltieForFullUnstake.mul(EXP).div(stakee.amount);
                }
                idx++;
            }
        }
    }


    function stakeInternal(address beneficiary, uint256 poolId, uint256 amount) internal {
        Pool storage pool = pools[poolId];
        require(address(pool.token) != address(0), "pool not found");
        require(!pool.closed, "pool closed");

        pool.token.safeTransferFrom(_msgSender(), address(this), amount);

        Stake[] storage userStakes = stakes[beneficiary][poolId];
        uint256 stakeId = userStakes.length;
        userStakes.push(Stake({
            start: block.timestamp,
            amount: amount
        }));
        pool.tvl = pool.tvl.add(amount);
        emit Staked(address(pool.token), poolId, beneficiary, stakeId, amount, pool.duration);
    }

    function unstakeExactStakeInternal(address beneficiary, uint256 poolId, uint256 stakeId, uint256 unstakeAmount) internal {
        Pool storage pool = pools[poolId];
        require(address(pool.token) != address(0), "pool not found");
        Stake[] storage userStakes = stakes[beneficiary][poolId];
        require(userStakes.length > 0, "no stakes");
        require(stakeId < userStakes.length, "wrong stake id");

        Stake storage stakee = userStakes[stakeId];
        (uint256 userAmount, uint256 penaltyAmount) = prepareUnstakeExactStake(pool, stakee, unstakeAmount);
        stakee.amount = stakee.amount.sub(unstakeAmount);
        emit Unstaked(address(pool.token), poolId, beneficiary, stakeId, unstakeAmount, penaltyAmount);
        pool.tvl = pool.tvl.sub(unstakeAmount);

        pool.token.safeTransfer(beneficiary, userAmount);
        if(penaltyAmount > 0) {
            pool.token.safeTransfer(penaltyBeneficiary, penaltyAmount);
        }
    }

    function unstakeExactStakesInternal(address beneficiary, uint256 poolId, uint256[] memory stakeIds, uint256[] memory amounts) internal {
        Pool storage pool = pools[poolId];
        require(address(pool.token) != address(0), "pool not found");
        Stake[] storage userStakes = stakes[beneficiary][poolId];
        require(userStakes.length > 0, "no stakes");

        //require(stakeIds.length == amounts.length, "arrays length mismatch"); //Here we assume its already checked
        uint256 prevStakeId;
        uint256 totalUserAmount;
        uint256 totalPenaltyAmount;

        for (uint256 i=0; i<stakeIds.length; i++) {
            uint256 stakeId = stakeIds[i];
            require(i==0 || prevStakeId < stakeId, "unsorted stake ids"); // Prevent unstaking from same stake twice
            require(stakeId < userStakes.length, "wrong stake id");
            prevStakeId = stakeId;

            Stake storage stakee = userStakes[stakeId];
            (uint256 userAmount, uint256 penaltyAmount) = prepareUnstakeExactStake(pool, stakee, amounts[i]);
            stakee.amount = stakee.amount.sub(amounts[i]);
            emit Unstaked(address(pool.token), poolId, beneficiary, stakeIds[i], amounts[i], penaltyAmount);

            totalUserAmount = totalUserAmount.add(userAmount);
            totalPenaltyAmount = totalPenaltyAmount.add(penaltyAmount);
        }

        pool.tvl = pool.tvl.sub(totalUserAmount).sub(totalPenaltyAmount);

        pool.token.safeTransfer(beneficiary, totalUserAmount);
        if(totalPenaltyAmount > 0) {
            pool.token.safeTransfer(penaltyBeneficiary, totalPenaltyAmount);
        }
    }
    
    function prepareUnstakeExactStake(Pool storage pool, Stake storage stakee, uint256 amount) internal view
    returns(uint256 userAmount, uint256 penaltyAmount) {
        require(stakee.start > 0, "incorrect stake"); // should never happen, but just to be sure...

        require(amount > 0, "wrong amount");
        require(amount <= stakee.amount, "high amount");

        penaltyAmount = calculateUnstakePenalty(pool, stakee, amount);
        require(penaltyAmount < amount, "unstake not available yet");
        userAmount = amount - penaltyAmount;
        return (userAmount, penaltyAmount);
    }

    /**
     * @notice Calculates penalty amount
     * @dev if penalty == unstakeAmount, that indicates that unstake is forbidden
     * @param pool Pool of the stake
     * @param stakee Stake to unstake from
     * @param unstakeAmount Amount to unstake
     * @return penalty amount
     */
    function calculateUnstakePenalty(Pool storage pool, Stake storage stakee, uint256 unstakeAmount) internal view returns(uint256) {
        uint256 timePassed = block.timestamp.sub(stakee.start);
        if(timePassed >= pool.duration) return 0;
        if(timePassed < pool.cliff) return unstakeAmount; //unstake is prohibited

        uint256 penaltyTimeLeft = pool.duration.sub(timePassed);
        uint256 linearVestingDuration = pool.duration.sub(pool.cliff); 
        // penaltyTimePeriod != 0 because if pool.duration == pool.cliff, then one of conditions above will be true
        return unstakeAmount.mul(pool.penalty).mul(penaltyTimeLeft).div(linearVestingDuration).div(EXP);
    }

}