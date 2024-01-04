pragma solidity 0.5.16;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IController.sol";
import "./Controllable.sol";

contract RewardTokenProfitNotifier is Controllable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public profitSharingNumerator;
    uint256 public profitSharingDenominator;
    address public rewardToken;

    constructor(address _storage, address _rewardToken)
        public
        Controllable(_storage)
    {
        rewardToken = _rewardToken;
        profitSharingNumerator = 0;
        profitSharingDenominator = 100;
        require(
            profitSharingNumerator < profitSharingDenominator,
            "invalid profit share"
        );
    }

    event ProfitLogInReward(
        uint256 profitAmount,
        uint256 feeAmount,
        uint256 timestamp
    );

    function notifyProfitInRewardToken(uint256 _rewardBalance) internal {
        if (_rewardBalance > 0 && profitSharingNumerator > 0) {
            uint256 feeAmount =
                _rewardBalance.mul(profitSharingNumerator).div(
                    profitSharingDenominator
                );
            emit ProfitLogInReward(_rewardBalance, feeAmount, block.timestamp);
            IERC20(rewardToken).safeApprove(controller(), 0);
            IERC20(rewardToken).safeApprove(controller(), feeAmount);

            IController(controller()).notifyFee(rewardToken, feeAmount);
        } else {
            emit ProfitLogInReward(0, 0, block.timestamp);
        }
    }

    function setProfitSharingNumerator(uint256 _profitSharingNumerator)
        external
        onlyGovernance
    {
        profitSharingNumerator = _profitSharingNumerator;
    }
}
