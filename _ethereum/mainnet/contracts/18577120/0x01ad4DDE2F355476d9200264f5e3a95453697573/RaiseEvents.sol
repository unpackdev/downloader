// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

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
import "./RequestTypes.sol";
import "./StorageTypes.sol";

/**************************************

    Raise events
    
**************************************/

// ToDo : NatSpec

/// @dev All events connected with raises.
library RaiseEvents {
    // -----------------------------------------------------------------------
    //                              Raise
    // -----------------------------------------------------------------------

    event NewRaise(
        address sender,
        StorageTypes.Raise raise,
        StorageTypes.RaiseDetails raiseDetails,
        StorageTypes.ERC20Asset erc20Asset,
        StorageTypes.BaseAsset baseAsset,
        uint256 badgeId,
        uint256 nonce
    );
    event RaiseRegistered(
        StorageTypes.Raise raise,
        StorageTypes.RaiseDetails raiseDetails,
        StorageTypes.ERC20Asset erc20Asset,
        StorageTypes.BaseAsset baseAsset,
        uint256 nonce
    );

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
