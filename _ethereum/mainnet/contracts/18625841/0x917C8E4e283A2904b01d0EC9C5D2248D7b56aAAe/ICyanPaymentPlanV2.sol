// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./PaymentPlanTypes.sol";

interface ICyanPaymentPlanV2 {
    function pay(uint256, bool) external payable;

    function getPlanStatus(uint256) external view returns (PaymentPlanStatus);

    function getCurrencyAddressByPlanId(uint256) external view returns (address);
}
