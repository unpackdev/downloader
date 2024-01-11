// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "IERC20.sol";
import "IERC721.sol";
import "IERC1155.sol";
import "TokenLibrary.sol";


library LotLibrary {

    using TokenLibrary for TokenLibrary.TokenValue;
    
    enum LotStatus {
        FOR_AUCTION,
        CANCELED,
        WITH_BETS,
        WITHDRAWN
    }
    
    struct Lot {
        address owner;
        address buyer;
        uint256 price;
        uint256 startTime;
        uint256 time;
        TokenLibrary.TokenValue token;
        IERC20 paymentContract;
        LotStatus status;
        uint256 royalty;
        address creator;
    }

    function transferToken(Lot storage lot, address from, address to) internal {
        lot.token.transferFrom(from, to);
    }
    
}
