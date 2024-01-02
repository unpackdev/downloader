// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./BaseAccessControl.sol";
import "./CoreFees.sol";
import "./DefinitiveAssets.sol";
import "./DefinitiveConstants.sol";
import "./DefinitiveErrors.sol";

abstract contract BaseFees is BaseAccessControl, CoreFees {
    using DefinitiveAssets for IERC20;

    constructor(CoreFeesConfig memory coreFeesConfig) CoreFees(coreFeesConfig) {}

    function updateFeeAccount(address payable _feeAccount) public override onlyDefinitiveAdmin {
        _updateFeeAccount(_feeAccount);
    }

    function _handleFeesOnAmount(address token, uint256 amount, uint256 feePct) internal returns (uint256 feeAmount) {
        uint256 mMaxFeePCT = DefinitiveConstants.MAX_FEE_PCT;
        if (feePct > mMaxFeePCT) {
            revert InvalidFeePercent();
        }

        feeAmount = (amount * feePct) / mMaxFeePCT;
        if (feeAmount > 0) {
            IERC20(token).safeTransfer(FEE_ACCOUNT, feeAmount);
        }
    }
}
