pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

import "./ClaimableStrategy.sol";
import "./IBooster.sol";
import "./IRewards.sol";
import "./ICVXRewards.sol";

/// @title HiveStrategy
/// @notice This is contract for yield farming strategy with EURxb token for investors
contract HiveStrategy is ClaimableStrategy {
    struct Settings {
        address crvRewards;
        address cvxRewards;
        address convexBooster;
        uint256 poolIndex;
    }

    Settings public poolSettings;

    function configure(
        address _wantAddress,
        address _controllerAddress,
        address _governance,
        Settings memory _poolSettings
    ) public onlyOwner initializer {
        _configure(_wantAddress, _controllerAddress, _governance);
        poolSettings = _poolSettings;
    }

    function setPoolIndex(uint256 _newPoolIndex) external onlyOwner {
        poolSettings.poolIndex = _newPoolIndex;
    }

    function checkPoolIndex(uint256 index) public view returns (bool) {
        IBooster.PoolInfo memory _pool = IBooster(poolSettings.convexBooster)
            .poolInfo(index);
        return _pool.lptoken == _want;
    }

    /// @dev Function that controller calls
    function deposit() external override onlyController {
        if (checkPoolIndex(poolSettings.poolIndex)) {
            IERC20 wantToken = IERC20(_want);
            uint256 _amount = wantToken.balanceOf(address(this));
            if (
                wantToken.allowance(
                    address(this),
                    poolSettings.convexBooster
                ) == 0
            ) {
                wantToken.approve(poolSettings.convexBooster, uint256(-1));
            }
            //true means that the received lp tokens will immediately be stakes
            IBooster(poolSettings.convexBooster).depositAll(
                poolSettings.poolIndex,
                true
            );
        }
    }

    function getRewards() external override {
        require(
            IRewards(poolSettings.crvRewards).getReward(),
            "!getRewardsCRV"
        );

        ICVXRewards(poolSettings.cvxRewards).getReward(true);
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IRewards(poolSettings.crvRewards).withdraw(_amount, true);

        require(
            IBooster(poolSettings.convexBooster).withdraw(
                poolSettings.poolIndex,
                _amount
            ),
            "!withdrawSome"
        );

        return _amount;
    }
}
