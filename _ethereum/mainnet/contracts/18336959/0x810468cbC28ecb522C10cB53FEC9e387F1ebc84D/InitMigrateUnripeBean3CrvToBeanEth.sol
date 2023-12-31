/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./AppStorage.sol";
import "./SafeERC20.sol";
import "./C.sol";
import "./LibDiamond.sol";
import "./LibUnripe.sol";

/**
 * Initializes the Migration of the Unripe LP underlying tokens from Bean:3Crv to Bean:Eth.
 */
contract InitMigrateUnripeBean3CrvToBeanEth {
    using SafeERC20 for IERC20;

    AppStorage internal s;

    function init() external {
        uint256 balanceOfUnderlying = s.u[C.UNRIPE_LP].balanceOfUnderlying;
        IERC20(s.u[C.UNRIPE_LP].underlyingToken).safeTransfer(
            LibDiamond.diamondStorage().contractOwner,
            balanceOfUnderlying
        );
        LibUnripe.decrementUnderlying(C.UNRIPE_LP, balanceOfUnderlying);
        LibUnripe.switchUnderlyingToken(C.UNRIPE_LP, C.BEAN_ETH_WELL);

        // Reset variable to 0 because it wasn't in BIP-36.
        delete s.season.withdrawSeasons;
    }
}