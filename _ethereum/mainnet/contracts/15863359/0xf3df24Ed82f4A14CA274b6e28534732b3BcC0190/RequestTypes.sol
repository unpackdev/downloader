// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io

**************************************/

import "./BaseTypes.sol";

library RequestTypes {

    // structs: requests
    struct BaseRequest {
        address sender;
        uint256 expiry;
        uint256 nonce;
    }
    struct CreateRaiseRequest {
        BaseTypes.Raise raise;
        BaseTypes.Vested vested;
        BaseTypes.Milestone[] milestones;
        BaseRequest base;
    }
    struct InvestRequest {
        string raiseId;
        uint256 investment;
        uint256 maxTicketSize;
        BaseRequest base;
    }

}
