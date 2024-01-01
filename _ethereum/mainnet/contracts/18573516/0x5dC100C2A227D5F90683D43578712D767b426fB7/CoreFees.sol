// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./ICoreFeesV1.sol";
import "./Context.sol";

struct CoreFeesConfig {
    address payable feeAccount;
}

abstract contract CoreFees is ICoreFeesV1, Context {
    address payable public FEE_ACCOUNT;

    constructor(CoreFeesConfig memory coreFeesConfig) {
        FEE_ACCOUNT = coreFeesConfig.feeAccount;
    }

    function _updateFeeAccount(address payable feeAccount) internal {
        FEE_ACCOUNT = feeAccount;
        emit FeeAccountUpdated(_msgSender(), feeAccount);
    }
}
