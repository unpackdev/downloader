// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IGmxRouter.sol";
import "./IGmxVault.sol";
import "./IGmxOrderBook.sol";
import "./IGmxPositionRouter.sol";

contract GmxConfig {
    IGmxRouter public immutable router;
    IGmxPositionRouter public immutable positionRouter;
    IGmxVault public immutable vault;
    IGmxOrderBook public immutable orderBook;
    bytes32 public immutable referralCode;
    uint public immutable maxPositions = 2;
    // The number of unexecuted requests a vault can have open at a time.
    uint public immutable maxOpenRequests = 2;
    // The number of unexecuted decrease orders a vault can have open at a time.
    uint public immutable maxOpenDecreaseOrders = 2;
    uint public immutable acceptablePriceDeviationBasisPoints = 200; // 2%

    constructor(
        address _gmxRouter,
        address _gmxPositionRouter,
        address _gmxVault,
        address _gmxOrderBook,
        bytes32 _gmxReferralCode
    ) {
        router = IGmxRouter(_gmxRouter);
        positionRouter = IGmxPositionRouter(_gmxPositionRouter);
        vault = IGmxVault(_gmxVault);
        orderBook = IGmxOrderBook(_gmxOrderBook);
        referralCode = _gmxReferralCode;
    }
}
