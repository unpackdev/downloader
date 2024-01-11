//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./variables.sol";

contract Events is Variables {
    event updateRebalancerLog(address auth_, bool isAuth_);

    event changeStatusLog(uint256 status_);

    event updateRatiosLog(
        uint16 maxLimit,
        uint16 maxLimitGap,
        uint16 minLimit,
        uint16 minLimitGap,
        uint16 stEthLimit,
        uint128 maxBorrowRate
    );

    event updateFeesLog(
        uint256 revenueFee_,
        uint256 withdrawalFee_,
        uint256 swapFee_,
        uint256 deleverageFee_
    );
}
