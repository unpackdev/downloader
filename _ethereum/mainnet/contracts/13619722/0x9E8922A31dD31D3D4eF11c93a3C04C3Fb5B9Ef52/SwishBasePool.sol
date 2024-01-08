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

    ISwishPoolManager.FeeInfo public feeInfo;

    function initialize(
        address _poolManager,
        string memory _name,
        uint256 _cvxPoolId,
        address[] memory _extraRewardTokens
    ) public initializer {
        __ReentrancyGuard_init();

        poolManager = _poolManager;
        cvxPoolId = _cvxPoolId;
        name = _name;

        bent = ISwishPoolManager(poolManager).rewardToken();
        (
            feeInfo.bentStaker,
            feeInfo.bentStakerFee,
            feeInfo.cvxStaker,
            feeInfo.cvxStakerFee
        ) = ISwishPoolManager(poolManager).feeInfo();

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

    function updateFee() external nonReentrant {
        _harvestFromConvex();
        _updateAccPerShare(false);
        (
            feeInfo.bentStaker,
            feeInfo.bentStakerFee,
            feeInfo.cvxStaker,
            feeInfo.cvxStakerFee
        ) = ISwishPoolManager(poolManager).feeInfo();
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
                pending[0] = _calcProRataRewards(bent, reward, 4);
            }
            pending[i + 1] = reward;
        }
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
    }

    function _calcAddedRewards()
        internal
        view
        returns (uint256[] memory addedRewards)
    {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        uint256 crvLpStakerFee = 10000 -
            feeInfo.bentStakerFee -
            feeInfo.cvxStakerFee;

        addedRewards = new uint256[](_rewardPoolsCount);
        addedRewards[0] =
            (IBaseRewardPool(crvRewards).earned(address(this)) *
                crvLpStakerFee) /
            10000;
        addedRewards[1] =
            (_calcProRataRewards(CVX, addedRewards[0], 1) * crvLpStakerFee) /
            10000;

        uint256 j = 0;
        uint256 extraRewardsLength = IBaseRewardPool(crvRewards)
            .extraRewardsLength();
        for (uint256 i = 0; i < extraRewardsLength; i++) {
            IVirtualBalanceRewardPool pool = IVirtualBalanceRewardPool(
                IBaseRewardPool(crvRewards).extraRewards(i)
            );
            address extraToken = pool.rewardToken();
            uint256 earned = (pool.earned(address(this)) * crvLpStakerFee) /
                10000;
            if (extraToken == CRV) {
                addedRewards[0] += earned;
            } else if (extraToken == CVX) {
                addedRewards[1] += earned;
            } else {
                addedRewards[2 + j] += earned;
                j++;
            }
        }

        for (uint256 i = 0; i < _rewardPoolsCount; i++) {
            addedRewards[i] += rewardPools[i].rewardToken.balanceOf(
                address(this)
            );
            uint256 rewardsBefore = rewardPools[i].lastReward +
                rewardPools[i].pendingReward;
            if (addedRewards[i] > rewardsBefore) {
                addedRewards[i] -= rewardsBefore;
            } else {
                // this can happen because cvx rewards is pro rata to crv rewards amount.
                addedRewards[i] = 0;
            }
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

                if (
                    rewardPools[i].rewardToken.balanceOf(address(this)) <
                    harvestAmount
                ) {
                    // this will happen only once.
                    _harvestFromConvex();
                }

                rewardPools[i].rewardToken.safeTransfer(
                    msg.sender,
                    harvestAmount
                );
                harvested = true;
            }
        }
    }

    function _harvestFromConvex() internal {
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

            if (claimBalances[i] > 0) {
                if (feeInfo.bentStakerFee > 0) {
                    // bentStakerFee to bentStaker
                    rewardPools[i].rewardToken.safeTransfer(
                        feeInfo.bentStaker,
                        (claimBalances[i] * feeInfo.bentStakerFee) / 10000
                    );
                }

                if (feeInfo.cvxStakerFee > 0) {
                    // cvxStakerFee to cvxStaker
                    rewardPools[i].rewardToken.safeTransfer(
                        feeInfo.cvxStaker,
                        (claimBalances[i] * feeInfo.cvxStakerFee) / 10000
                    );
                }
            }
        }
    }

    /**
     * @notice from convex/bent token contract
     */
    function _calcProRataRewards(
        address token,
        uint256 baseEarned,
        uint256 multiplier
    ) internal view returns (uint256) {
        uint256 supply = IConvexToken(token).totalSupply();
        if (supply == 0) {
            return baseEarned;
        }
        uint256 totalCliffs = IConvexToken(token).totalCliffs();
        uint256 cliff = supply / IConvexToken(token).reductionPerCliff();

        if (cliff < totalCliffs) {
            uint256 reduction = totalCliffs - cliff;
            uint256 _amount = baseEarned;

            _amount = ((_amount * reduction) * multiplier) / totalCliffs;

            //supply cap check
            uint256 amtTillMax = IConvexToken(token).maxSupply() - supply;
            if (_amount > amtTillMax) {
                _amount = amtTillMax;
            }
            return _amount;
        }
        return 0;
    }

    function _mint(address _user, uint256 _amount) internal {
        balanceOf[_user] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _user, uint256 _amount) internal {
        balanceOf[_user] -= _amount;
        totalSupply -= _amount;
    }
}
