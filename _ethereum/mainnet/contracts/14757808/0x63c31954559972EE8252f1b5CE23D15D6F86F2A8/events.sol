//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./variables.sol";

contract Events is Variables {
    event updateAuthLog(address auth_);

    event updateRebalancerLog(address auth_, bool isAuth_);

    event updateRatiosLog(
        uint16 maxLimit,
        uint16 minLimit,
        uint16 gap,
        uint128 maxBorrowRate
    );

    event updateRevenueFeeLog(uint256 oldRevenueFee_, uint256 newRevenueFee_);

    event updateWithdrawalFeeLog(
        uint256 oldWithdrawalFee_,
        uint256 newWithdrawalFee_
    );

    event changeStatusLog(uint256 status_);

    event supplyLog(address token_, uint256 amount_, address to_);

    event withdrawLog(uint256 amount_, address to_);

    event rebalanceOneLog(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address[] vaults_,
        uint256[] amts_,
        uint256 excessDebt_,
        uint256 paybackDebt_,
        uint256 totalAmountToSwap_,
        uint256 extraWithdraw_,
        uint256 unitAmt_
    );

    event rebalanceTwoLog(
        uint256 withdrawAmt_,
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        uint256 saveAmt_,
        uint256 unitAmt_
    );
}
