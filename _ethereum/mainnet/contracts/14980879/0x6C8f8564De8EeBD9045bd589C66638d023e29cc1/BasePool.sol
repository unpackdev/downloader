// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./MathUpgradeable.sol";

import "./IBasePool.sol";
import "./IVoteAnzenToken.sol";

abstract contract BasePool is IBasePool, AccessControlEnumerableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCastUpgradeable for uint256;

    IVoteAnzenToken public veAnzenToken;
    IERC20Upgradeable public depositToken;
    IERC20Upgradeable public rewardToken;
    
    event RewardsDistributed(address indexed, uint256 amount);

    function __BasePool_init(
        address _depositToken,
        address _rewardToken,
        address _veAnzenToken
    ) internal {
        require(_veAnzenToken != address(0), "BasePool.constructor: veAnzen token must be set");
        require(_depositToken != address(0), "BasePool.constructor: Deposit token must be set");
        depositToken = IERC20Upgradeable(_depositToken);
        rewardToken = IERC20Upgradeable(_rewardToken);
        veAnzenToken = IVoteAnzenToken(_veAnzenToken);

        __Context_init();
        __AccessControlEnumerable_init();
    }

    // Used to transfer reward tokens to this staking pool contract
    function distributeRewards(uint256 _amount) external override {
        rewardToken.safeTransferFrom(_msgSender(), address(this), _amount);
        emit RewardsDistributed(_msgSender(), _amount);
    }

}
