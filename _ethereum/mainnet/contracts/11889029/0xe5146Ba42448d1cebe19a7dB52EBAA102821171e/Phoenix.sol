//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./Ownable.sol";

interface IFETStaking {
    function _accruedGlobalPrincipal() external view returns (uint256);

    function getStakeForUser(address user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
}

contract Phoenix is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public rewardStartBlock;
    uint256 public MTLXPerBlock;
    address public FETStaking;
    address public MTLXToken;
    address public guardian;

    struct Distribution {
        uint256 lastRewardBlock;
        uint256 rewardDebt;
        uint256 FETStaked;
        bool isEnrolled;
    }

    struct DistributionIndex {
        uint256 lastScannedBlock;
        uint256 accuMTLXPerFET;
        uint256 globalPrincipal;
    }

    DistributionIndex public distributionIndex;

    mapping(address => Distribution) public distributions;

    constructor(
        uint256 _rewardStartBlock,
        uint256 _MTLXPerBlock,
        address _FETStaking,
        address _MTLXToken,
        address _guardian
    ) {
        rewardStartBlock = _rewardStartBlock;
        MTLXPerBlock = _MTLXPerBlock;
        FETStaking = _FETStaking;
        MTLXToken = _MTLXToken;
        distributionIndex.lastScannedBlock = _rewardStartBlock;
        guardian = _guardian;
    }

    function _updateDistributionIndex() internal {
        require(
            distributionIndex.lastScannedBlock < block.number,
            "Cannot update index ahead of time"
        );

        uint256 globalPrincipleAccrued =
            IFETStaking(FETStaking)._accruedGlobalPrincipal();

        if (distributionIndex.globalPrincipal == 0) {
            distributionIndex.lastScannedBlock = block.number;
            distributionIndex.globalPrincipal = globalPrincipleAccrued;
            return;
        }

        uint256 blockDifference =
            block.number.sub(distributionIndex.lastScannedBlock);

        distributionIndex.accuMTLXPerFET = distributionIndex.accuMTLXPerFET.add(
            blockDifference.mul(MTLXPerBlock).mul(1e18).div(
                distributionIndex.globalPrincipal
            )
        );
        distributionIndex.lastScannedBlock = block.number;
        distributionIndex.globalPrincipal = globalPrincipleAccrued;
    }

    function getAccumulatedRewards(address user) public view returns (uint256) {
        Distribution storage distribution = distributions[user];
        if (distribution.FETStaked == 0) {
            return 0;
        }

        (uint256 userFETStaked, , , ) =
            IFETStaking(FETStaking).getStakeForUser(user);

        uint256 FETStaked = distribution.FETStaked;
        if (userFETStaked < distribution.FETStaked) {
            FETStaked = userFETStaked;
        }

        uint256 accMTLXPerFET = distributionIndex.accuMTLXPerFET;
        if (block.number > distributionIndex.lastScannedBlock) {
            uint256 blockDifference =
                block.number.sub(distributionIndex.lastScannedBlock);
            uint256 MTLXReward = blockDifference.mul(MTLXPerBlock);
            accMTLXPerFET = accMTLXPerFET.add(
                MTLXReward.mul(1e18).div(distributionIndex.globalPrincipal)
            );
        }
        uint256 stackedRewards = FETStaked.mul(accMTLXPerFET).div(1e18);

        if (stackedRewards <= distribution.rewardDebt) {
            return 0;
        }
        return stackedRewards.sub(distribution.rewardDebt);
    }

    function claimRewards() public whenNotPaused {
        _updateDistributionIndex();
        Distribution storage distribution = distributions[msg.sender];
        require(
            distribution.lastRewardBlock < block.number,
            "Cannot claim the rewards twice in the same block"
        );
        (uint256 userFETStaked, , , ) =
            IFETStaking(FETStaking).getStakeForUser(msg.sender);

        if (userFETStaked < distribution.FETStaked) {
            distribution.FETStaked = userFETStaked;
        }

        if (distribution.isEnrolled == false) {
            distribution.rewardDebt = userFETStaked
                .mul(distributionIndex.accuMTLXPerFET)
                .div(1e18);
            distribution.isEnrolled = true;
        }

        uint256 MTLXRewards = getAccumulatedRewards(msg.sender);

        if (MTLXRewards > 0) {
            distribution.rewardDebt = userFETStaked
                .mul(distributionIndex.accuMTLXPerFET)
                .div(1e18);
            IERC20(MTLXToken).safeTransfer(msg.sender, MTLXRewards);
        }
        distribution.FETStaked = userFETStaked;
        distribution.lastRewardBlock = block.number;
    }

    // Admin Methods
    function pauseDistribution() public onlyOwner {
        _pause();
    }

    function resumeDistribution() public onlyOwner {
        _unpause();
    }

    function setMTLXRewardPerBlock(uint256 _newReward) public onlyOwner {
        _updateDistributionIndex();
        MTLXPerBlock = _newReward;
    }

    function withdrawAdminMTLX(uint256 amount) public onlyOwner {
        IERC20(MTLXToken).safeTransfer(msg.sender, amount);
    }

    // Guardian Method

    function rebalanceUserFETStakes(address[] calldata users) public {
        require(
            msg.sender == guardian,
            "Only Phoenix Guardian can trigger rebalance"
        );
        _updateDistributionIndex();

        for (uint256 i = 0; i < users.length; i++) {
            (uint256 userFETStaked, , , ) =
                IFETStaking(FETStaking).getStakeForUser(users[i]);

            Distribution storage distribution = distributions[users[i]];

            if (distribution.FETStaked > userFETStaked) {
                distribution.FETStaked = userFETStaked;
            }
        }
    }
}
