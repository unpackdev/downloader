// SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./LibGovernance.sol";
import "./LibRouter.sol";

library LibFeeExternal {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 constant STORAGE_POSITION = keccak256("fee.external.storage");

    struct Storage {
        bool initialized;

        // The current external fee
        uint256 externalFee;

        // Where to send the external fees
        address externalFeeAddress;
    }

    function chargeExternalFee() internal returns (uint256) {
        LibFeeExternal.Storage storage fes = LibFeeExternal.feeExternalStorage();
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        if (fes.externalFee != 0) {
            require(fes.externalFeeAddress != address(0), "External fee set, but no receiver address");
            IERC20(rs.albtToken).safeTransferFrom(msg.sender, fes.externalFeeAddress, fes.externalFee);
        }

        return fes.externalFee;
    }

    function feeExternalStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

}
