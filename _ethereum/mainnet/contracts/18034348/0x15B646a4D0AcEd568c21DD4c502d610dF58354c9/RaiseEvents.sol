// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

// Local imports
import "./BaseTypes.sol";

/**************************************

    Raise events

**************************************/

/// All events connected with raises.
library RaiseEvents {
    // -----------------------------------------------------------------------
    //                              Raise
    // -----------------------------------------------------------------------

    event NewRaise(address sender, BaseTypes.Raise raise, uint256 badgeId, bytes32 message);

    // -----------------------------------------------------------------------
    //                              Early Stage
    // -----------------------------------------------------------------------

    event TokenSet(address sender, string raiseId, address token);

    // -----------------------------------------------------------------------
    //                              Investing
    // -----------------------------------------------------------------------

    event NewInvestment(address sender, string raiseId, uint256 investment, bytes32 message, uint256 data);

    // -----------------------------------------------------------------------
    //                              Refund
    // -----------------------------------------------------------------------

    event InvestmentRefunded(address sender, string raiseId, uint256 amount);
    event CollateralRefunded(address startup, string raiseId, uint256 amount);

    // -----------------------------------------------------------------------
    //                              Reclaim
    // -----------------------------------------------------------------------

    event UnsoldReclaimed(address startup, string raiseId, uint256 amount);
}
