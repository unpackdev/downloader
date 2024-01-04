pragma solidity 0.5.16;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IController.sol";
import "./Controllable.sol";

contract ProfitNotifier is Controllable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public profitSharingNumerator;
    uint256 public profitSharingDenominator;
    address public underlying;

    event ProfitLog(
        uint256 oldBalance,
        uint256 newBalance,
        uint256 feeAmount,
        uint256 timestamp
    );

    constructor(address _storage, address _underlying)
        public
        Controllable(_storage)
    {
        underlying = _underlying;
        profitSharingNumerator = 0;
        profitSharingDenominator = 100;
        require(
            profitSharingNumerator < profitSharingDenominator,
            "invalid profit share"
        );
    }

    function notifyProfit(uint256 oldBalance, uint256 newBalance) internal {
        if (newBalance > oldBalance && profitSharingNumerator > 0) {
            uint256 profit = newBalance.sub(oldBalance);
            uint256 feeAmount =
                profit.mul(profitSharingNumerator).div(
                    profitSharingDenominator
                );
            emit ProfitLog(oldBalance, newBalance, feeAmount, block.timestamp);

            IERC20(underlying).safeApprove(controller(), 0);
            IERC20(underlying).safeApprove(controller(), feeAmount);
            IController(controller()).notifyFee(underlying, feeAmount);
        } else {
            emit ProfitLog(oldBalance, newBalance, 0, block.timestamp);
        }
    }

    function setProfitSharingNumerator(uint256 _profitSharingNumerator)
        external
        onlyGovernance
    {
        profitSharingNumerator = _profitSharingNumerator;
    }
}
