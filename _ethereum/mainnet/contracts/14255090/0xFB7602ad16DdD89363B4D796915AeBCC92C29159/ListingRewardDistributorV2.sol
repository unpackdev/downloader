// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./SafeERC20.sol";
import "./ECDSA.sol";

import "./IStakeFor.sol";

contract ListingRewardDistributorV2 is Ownable, Pausable {
    using SafeERC20 for IERC20;

    uint256 public maxRewardPerRound;
    uint256 public maxRoundsPerClaim;

    uint256 public currentRound;
    uint256 public totalRewardDistributed;

    uint256 public immutable operatorBufferInBlocks;
    uint256 public pausedAt;

    IStakeFor public stakingPool;
    IERC20 public immutable x2y2Token;

    // round => user => amount
    mapping(address => uint256) public userClaimedTotal;
    mapping(uint256 => mapping(address => uint256)) public rewardClaimed;
    mapping(address => bool) public signers;

    event Reward(address user, uint256 round, uint256 amount);
    event NewRound(uint256 round);
    event StakingPoolUpdate(address pool);
    event SettingsUpdate(uint256 maxReward, uint256 maxRounds);
    event SignerUpdate(address signer, bool isRemoval);

    constructor(
        uint256 _maxReward,
        uint256 _maxRound,
        IERC20 _x2y2Token,
        IStakeFor _stakingPool,
        address _signer
    ) {
        maxRewardPerRound = _maxReward;
        maxRoundsPerClaim = _maxRound;

        x2y2Token = _x2y2Token;
        stakingPool = _stakingPool;

        if (_signer != address(0)) {
            signers[_signer] = true;
        }

        operatorBufferInBlocks = 6500 * 3; // 3 days
    }

    function pause() external onlyOwner {
        pausedAt = block.number;
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateSigners(address[] memory toAdd, address[] memory toRemove) public onlyOwner {
        for (uint256 i = 0; i < toAdd.length; i++) {
            signers[toAdd[i]] = true;
            emit SignerUpdate(toAdd[i], false);
        }
        for (uint256 i = 0; i < toRemove.length; i++) {
            delete signers[toRemove[i]];
            emit SignerUpdate(toRemove[i], true);
        }
    }

    function operatorWithdraw(IERC20 token, uint256 amount) external whenPaused onlyOwner {
        require(pausedAt + operatorBufferInBlocks >= block.number, 'Owner: wait for buffer');
        token.safeTransfer(msg.sender, amount);
    }

    function updateSetting(uint256 _maxReward, uint256 _maxRound) external onlyOwner {
        maxRewardPerRound = _maxReward;
        maxRoundsPerClaim = _maxRound;
        emit SettingsUpdate(_maxReward, _maxRound);
    }

    function updateStakingPool(IStakeFor pool_) external onlyOwner {
        stakingPool = pool_;
        emit StakingPoolUpdate(address(pool_));
    }

    function updateRound(uint256 newRound) external onlyOwner {
        currentRound += 1;
        require(currentRound == newRound, 'Owner: fail to set new round');
        emit NewRound(newRound);
    }

    function claim(
        uint256 round,
        uint256[] calldata rewards,
        bool staking,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused {
        require(rewards.length > 0, 'Claim: no rewards to be distributed');
        require(rewards.length <= maxRoundsPerClaim, 'Claim: exceeds maximum rounds');
        require(round > 0 && round == currentRound, 'Claim: current round only');

        address signer = ECDSA.recover(keccak256(abi.encode(round, rewards, msg.sender)), v, r, s);
        require(signers[signer], 'Claim: signer error');

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < rewards.length; i++) {
            uint256 rnd = round - i;
            require(rnd > 0, 'Claim: illegal round');
            uint256 amt = rewards[i];
            require(amt <= maxRewardPerRound, 'Claim: exceeds max reward limit');
            if (amt > 0 && rewardClaimed[rnd][msg.sender] == 0) {
                rewardClaimed[rnd][msg.sender] = amt;
                totalAmount += amt;
                emit Reward(msg.sender, round, amt);
            }
        }

        require(totalAmount > 0, 'Claim: no rewards');
        totalRewardDistributed += totalAmount;
        userClaimedTotal[msg.sender] += totalAmount;

        if (staking) {
            require(address(stakingPool) != address(0), 'Claim: cannot stake to address(0)');
            x2y2Token.approve(address(stakingPool), totalAmount);
            stakingPool.depositFor(msg.sender, totalAmount);
        } else {
            x2y2Token.safeTransfer(msg.sender, totalAmount);
        }
    }
}
