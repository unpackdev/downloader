// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./WrapperToken.sol";
import "./IBSLendingPair.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title CollateralWrapperToken
/// @author @samparsky
////////////////////////////////////////////////////////////////////////////////////////////

contract CollateralWrapperToken is WrapperToken {

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint256 maxWithdrawAllowed = IBSLendingPair(this.owner()).getMaxWithdrawAllowed(sender);
        require(amount <= maxWithdrawAllowed, "EXCEEDS_ALLOWED");

        super._transfer(sender, recipient, amount);
    }


}
