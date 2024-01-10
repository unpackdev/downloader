//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./variables.sol";

contract Events is Variables {

    event updateAuthLog(address auth_);

    event updateRebalancerLog(address auth_, bool isAuth_);

    event updateRatesLog(uint16 maxLimit, uint16 minLimit, uint16 gap, uint128 maxBorrowRate);

    event updateRevenueFeeLog(uint oldRevenueFee_, uint newRevenueFee_);

    event updateWithdrawalFeeLog(uint oldWithdrawalFee_, uint newWithdrawalFee_);

    event supplyLog(address token_, uint256 amount_, address to_);

    event withdrawLog(uint256 amount_, address to_);

    event rebalanceOneLog(
        address flashTkn_,
        uint flashAmt_,
        uint route_,
        uint excessDebt_,
        uint paybackDebt_,
        uint totalAmountToSwap_,
        uint extraWithdraw_,
        uint unitAmt_
    );

    event rebalanceTwoLog(
        uint withdrawAmt_,
        address flashTkn_,
        uint flashAmt_,
        uint route_,
        uint saveAmt_,
        uint unitAmt_
    );
}
