// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./Errors.sol";
import "./IBentPool.sol";
import "./IBentPoolManager.sol";
import "./IConvexBooster.sol";
import "./IBaseRewardPool.sol";
import "./IConvexToken.sol";
import "./IVirtualBalanceRewardPool.sol";
import "./BentBaseMasterchef.sol";

contract BentBasePool is
    BentBaseMasterchef,
    ReentrancyGuardUpgradeable,
    IBentPool
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user);

    address public constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant CONVEX_BOOSTER =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;

    address public bent;

    address public poolManager;
    address public override lpToken;
    uint256 public cvxPoolId;
    address public crvRewards;

    string public name;

    uint256 public windowLength;
    uint256 public endRewardBlock; // end block of rewards stream
    uint256 public lastRewardBlock; // last block of rewards streamed

    function initialize(
        address _poolManager,
        string memory _name,
        uint256 _cvxPoolId,
        address[] memory _extraRewardTokens,
        uint256 _windowLength // around 7 days
    ) public initializer {
        __ReentrancyGuard_init();

        poolManager = _poolManager;
        cvxPoolId = _cvxPoolId;
        name = _name;

        bent = IBentPoolManager(poolManager).rewardToken();

        rewardPools[0].rewardToken = IERC20Upgradeable(CRV);
        rewardPools[1].rewardToken = IERC20Upgradeable(CVX);

        (lpToken, , , crvRewards, , ) = IConvexBooster(CONVEX_BOOSTER).poolInfo(
            _cvxPoolId
        );
        uint256 extraRewardsLength = _extraRewardTokens.length;
        for (uint256 i = 0; i < extraRewardsLength; i++) {
            rewardPools[i + 2].rewardToken = IERC20Upgradeable(
                _extraRewardTokens[i]
            );
        }
        rewardPoolsCount = 2 + extraRewardsLength;

        windowLength = _windowLength;
    }

    function pendingReward(address user)
        external
        view
        returns (uint256[] memory pending)
    {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        pending = new uint256[](_rewardPoolsCount + 1);

        uint256[] memory addedRewards = _calcAddedRewards();
        for (uint256 i = 0; i < _rewardPoolsCount; i++) {
            uint256 reward = super.pendingReward(i, user, addedRewards[i]);
            if (i == 1) {
                // calculate bent rewards amount based on CVX reward
                pending[0] = _getBentEarned(reward);
            }
            pending[i + 1] = reward;
        }
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount != 0, Errors.ZERO_AMOUNT);

        _updateAccPerShare(true);

        uint256 _before = IERC20(lpToken).balanceOf(address(this));
        IERC20Upgradeable(lpToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        uint256 _after = IERC20(lpToken).balanceOf(address(this));
        // Additional check for deflationary tokens
        _amount = _after - _before;

        _mint(msg.sender, _amount);

        // deposit to the convex booster
        IERC20Upgradeable(lpToken).safeApprove(CONVEX_BOOSTER, 0);
        IERC20Upgradeable(lpToken).safeApprove(CONVEX_BOOSTER, _amount);
        IConvexBooster(CONVEX_BOOSTER).deposit(cvxPoolId, _amount, true);

        _updateUserRewardDebt();

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        require(
            balanceOf[msg.sender] >= _amount && _amount != 0,
            Errors.INVALID_AMOUNT
        );

        _updateAccPerShare(true);

        _burn(msg.sender, _amount);

        // withdraw from the convex booster
        IBaseRewardPool(crvRewards).withdrawAndUnwrap(_amount, false);

        // transfer to msg.sender
        IERC20Upgradeable(lpToken).safeTransfer(msg.sender, _amount);

        _updateUserRewardDebt();

        emit Withdraw(msg.sender, _amount);
    }

    function harvest() external virtual nonReentrant {
        _updateAccPerShare(true);

        require(_harvest(), Errors.NO_PENDING_REWARD);

        _updateUserRewardDebt();

        emit Harvest(msg.sender);
    }

    function harvestFromConvex() external nonReentrant {
        _updateAccPerShare(false);

        uint256 i;
        uint256[] memory claimBalances = new uint256[](rewardPoolsCount);
        // save balances before claim
        for (i = 0; i < rewardPoolsCount; i++) {
            claimBalances[i] = rewardPools[i].rewardToken.balanceOf(
                address(this)
            );
        }

        IBaseRewardPool(crvRewards).getReward(address(this), true);

        (
            uint256 harvesterFee,
            address bentStaker,
            uint256 bentStakerFee,
            address cvxStaker,
            uint256 cvxStakerFee
        ) = IBentPoolManager(poolManager).feeInfo();

        for (i = 0; i < rewardPoolsCount; i++) {
            claimBalances[i] =
                rewardPools[i].rewardToken.balanceOf(address(this)) -
                claimBalances[i];

            uint256 remaining = claimBalances[i];
            if (claimBalances[i] > 0) {
                if (harvesterFee > 0) {
                    // harvesterFee to msg.sender
                    uint256 fee = (claimBalances[i] * harvesterFee) / 10000;
                    rewardPools[i].rewardToken.safeTransfer(msg.sender, fee);
                    remaining -= fee;
                }

                if (bentStakerFee > 0) {
                    // bentStakerFee to bentStaker
                    uint256 fee = (claimBalances[i] * bentStakerFee) / 10000;
                    rewardPools[i].rewardToken.safeTransfer(bentStaker, fee);
                    remaining -= fee;
                }

                if (cvxStakerFee > 0) {
                    // cvxStakerFee to cvxStaker
                    uint256 fee = (claimBalances[i] * cvxStakerFee) / 10000;
                    rewardPools[i].rewardToken.safeTransfer(cvxStaker, fee);
                    remaining -= fee;
                }
            }

            if (endRewardBlock > lastRewardBlock) {
                rewardPools[i].rewardRate =
                    (rewardPools[i].rewardRate *
                        (endRewardBlock - lastRewardBlock) +
                        remaining *
                        1e36) /
                    windowLength;
            } else {
                rewardPools[i].rewardRate = (remaining * 1e36) / windowLength;
            }
        }

        endRewardBlock = lastRewardBlock + windowLength;
    }

    // Internal Functions

    function _updateAccPerShare(bool withdrawReward) internal {
        uint256[] memory addedRewards = _calcAddedRewards();
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; i++) {
            super.updateAccPerShare(i, addedRewards[i]);
            if (withdrawReward) {
                super.withdrawReward(i, msg.sender);
            }
        }

        lastRewardBlock = block.number;
    }

    function _calcAddedRewards()
        internal
        view
        returns (uint256[] memory addedRewards)
    {
        uint256 startBlock = endRewardBlock > lastRewardBlock + windowLength
            ? endRewardBlock - windowLength
            : lastRewardBlock;
        uint256 endBlock = block.number > endRewardBlock
            ? endRewardBlock
            : block.number;
        uint256 duration = endBlock > startBlock ? endBlock - startBlock : 0;

        uint256 _rewardPoolsCount = rewardPoolsCount;
        addedRewards = new uint256[](_rewardPoolsCount);
        for (uint256 i = 0; i < _rewardPoolsCount; i++) {
            addedRewards[i] = (rewardPools[i].rewardRate * duration) / 1e36;
        }
    }

    function _updateUserRewardDebt() internal {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; i++) {
            super.updateUserRewardDebt(i, msg.sender);
        }
    }

    function _harvest() internal returns (bool harvested) {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; i++) {
            uint256 harvestAmount = super.harvest(i, msg.sender);
            if (harvestAmount > 0) {
                if (i == 1) {
                    // CVX
                    IBentPoolManager(poolManager).mint(
                        msg.sender,
                        harvestAmount
                    );
                }

                rewardPools[i].rewardToken.safeTransfer(
                    msg.sender,
                    harvestAmount
                );
                harvested = true;
            }
        }
    }

    function _mint(address _user, uint256 _amount) internal {
        balanceOf[_user] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _user, uint256 _amount) internal {
        balanceOf[_user] -= _amount;
        totalSupply -= _amount;
    }

    /**
     * @notice from bent token contract
     */
    function _getBentEarned(uint256 cvxEarned) internal view returns (uint256) {
        uint256 supply = IConvexToken(bent).totalSupply();
        if (supply == 0) {
            return cvxEarned;
        }
        uint256 totalCliffs = IConvexToken(bent).totalCliffs();
        uint256 cliff = supply / IConvexToken(bent).reductionPerCliff();

        if (cliff < totalCliffs) {
            uint256 reduction = totalCliffs - cliff;
            uint256 _amount = cvxEarned;

            _amount = ((_amount * reduction) * 20) / totalCliffs;

            //supply cap check
            uint256 amtTillMax = IConvexToken(bent).maxSupply() - supply;
            if (_amount > amtTillMax) {
                _amount = amtTillMax;
            }
            return _amount;
        }
        return 0;
    }
}
