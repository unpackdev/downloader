// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./Errors.sol";
import "./ISwishPool.sol";
import "./ISwishPoolManager.sol";
import "./IConvexBooster.sol";
import "./IBaseRewardPool.sol";
import "./IConvexToken.sol";
import "./IVirtualBalanceRewardPool.sol";
import "./SwishBaseMasterchef.sol";

contract SwishBasePool is
    SwishBaseMasterchef,
    ReentrancyGuardUpgradeable,
    ISwishPool
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
    uint256 internal lastRewardBlock; // bent reward last block

    string public name;

    function initialize(
        address _poolManager,
        uint256 _cvxPoolId,
        string memory _name
    ) public initializer {
        __ReentrancyGuard_init();

        poolManager = _poolManager;
        cvxPoolId = _cvxPoolId;
        name = _name;

        bent = ISwishPoolManager(poolManager).rewardToken();

        rewardPools[0].rewardToken = IERC20Upgradeable(CRV);
        rewardPools[1].rewardToken = IERC20Upgradeable(CVX);

        (lpToken, , , crvRewards, , ) = IConvexBooster(CONVEX_BOOSTER).poolInfo(
            _cvxPoolId
        );
        uint256 extraRewardsLength = IBaseRewardPool(crvRewards)
            .extraRewardsLength();
        for (uint256 i = 0; i < extraRewardsLength; i++) {
            rewardPools[i + 2].rewardToken = IERC20Upgradeable(
                IVirtualBalanceRewardPool(
                    IBaseRewardPool(crvRewards).extraRewards(i)
                ).rewardToken()
            );
        }
        rewardPoolsCount = 2 + extraRewardsLength;
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
                pending[0] = _getSwishEarned(reward);
            }
            pending[i + 1] = reward;
        }
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount != 0, Errors.ZERO_AMOUNT);

        _updateAccPerShare();

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

        _updateAccPerShare();

        _burn(msg.sender, _amount);

        // withdraw from the convex booster
        IBaseRewardPool(crvRewards).withdrawAndUnwrap(_amount, false);

        // transfer to msg.sender
        IERC20Upgradeable(lpToken).safeTransfer(msg.sender, _amount);

        _updateUserRewardDebt();

        emit Withdraw(msg.sender, _amount);
    }

    function harvest() external virtual nonReentrant {
        _updateAccPerShare();

        require(_harvest(), Errors.NO_PENDING_REWARD);

        _updateUserRewardDebt();

        emit Harvest(msg.sender);
    }

    function harvestFromConvex() external nonReentrant {
        uint256 i;
        uint256[] memory claimBalances = new uint256[](rewardPoolsCount);
        // save balances before claim
        for (i = 0; i < rewardPoolsCount; i++) {
            claimBalances[i] = rewardPools[i].rewardToken.balanceOf(
                address(this)
            );
        }

        IBaseRewardPool(crvRewards).getReward(address(this), true);

        for (i = 0; i < rewardPoolsCount; i++) {
            claimBalances[i] =
                rewardPools[i].rewardToken.balanceOf(address(this)) -
                claimBalances[i];
        }
        (
            uint256 harvesterFee,
            address bentStaker,
            uint256 bentStakerFee,
            address cvxStaker,
            uint256 cvxStakerFee
        ) = ISwishPoolManager(poolManager).feeInfo();

        for (i = 0; i < rewardPoolsCount; i++) {
            if (claimBalances[i] > 0) {
                if (harvesterFee > 0) {
                    // harvesterFee to msg.sender
                    rewardPools[i].rewardToken.safeTransfer(
                        msg.sender,
                        (claimBalances[i] * harvesterFee) / 10000
                    );
                }

                if (bentStakerFee > 0) {
                    // bentStakerFee to bentStaker
                    rewardPools[i].rewardToken.safeTransfer(
                        bentStaker,
                        (claimBalances[i] * bentStakerFee) / 10000
                    );
                }

                if (cvxStakerFee > 0) {
                    // cvxStakerFee to cvxStaker
                    rewardPools[i].rewardToken.safeTransfer(
                        cvxStaker,
                        (claimBalances[i] * cvxStakerFee) / 10000
                    );
                }
            }
        }
    }

    // Internal Functions

    function _updateAccPerShare() internal {
        uint256[] memory addedRewards = _calcAddedRewards();
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; i++) {
            super.updateAccPerShare(i, addedRewards[i]);
            super.withdrawReward(i, msg.sender);
        }

        lastRewardBlock = block.number;
    }

    function _calcAddedRewards()
        internal
        view
        returns (uint256[] memory addedRewards)
    {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        addedRewards = new uint256[](_rewardPoolsCount);

        for (uint256 i = 0; i < _rewardPoolsCount; i++) {
            addedRewards[i] =
                rewardPools[i].rewardToken.balanceOf(address(this)) -
                rewardPools[i].lastReward -
                rewardPools[i].pendingReward;
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
                    ISwishPoolManager(poolManager).mint(
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

    function _getSwishEarned(uint256 cvxEarned) internal view returns (uint256) {
        uint256 supply = IConvexToken(bent).totalSupply();
        if (supply == 0) {
            return cvxEarned;
        }
        uint256 totalCliffs = IConvexToken(bent).totalCliffs();
        uint256 cliff = supply / IConvexToken(bent).reductionPerCliff();

        if (cliff < totalCliffs) {
            uint256 reduction = totalCliffs - cliff;
            uint256 _amount = cvxEarned;

            _amount = (_amount * reduction) / totalCliffs;

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
